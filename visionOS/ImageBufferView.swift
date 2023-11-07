//
//  ImageBufferView.swift
//  visionOS
//
//  Created by Saagar Jha on 10/10/23.
//

import MetalKit
import SwiftUI

struct ImageBufferView: View, Equatable {
	let imageBuffer: CVImageBuffer
	var mask: Bool = false
	static var useMetal: Bool {
		#if targetEnvironment(simulator)
			true
		#else
			false
		#endif
	}

	var body: some View {
		if ImageBufferView.useMetal {
			AcceleratedImageBufferView<MetalAccelerator>(imageBuffer: imageBuffer)
		} else {
			if mask {
				let image = CIImage(cvImageBuffer: imageBuffer)
				let cgImage = CIContext().createCGImage(image, from: image.extent)!
				Image(uiImage: UIImage(cgImage: cgImage))
					.resizable()
					.aspectRatio(contentMode: .fit)
			} else {
				AcceleratedImageBufferView<CoreAnimationAccelerator>(imageBuffer: imageBuffer)
			}
		}
	}

	static func == (lhs: Self, rhs: Self) -> Bool {
		guard !useMetal else {
			return false
		}

		CVPixelBufferLockBaseAddress(lhs.imageBuffer, .readOnly)
		defer {
			CVPixelBufferUnlockBaseAddress(lhs.imageBuffer, .readOnly)
		}
		let left = UnsafeRawBufferPointer(start: CVPixelBufferGetBaseAddress(lhs.imageBuffer), count: CVPixelBufferGetDataSize(lhs.imageBuffer))

		CVPixelBufferLockBaseAddress(rhs.imageBuffer, .readOnly)
		defer {
			CVPixelBufferUnlockBaseAddress(rhs.imageBuffer, .readOnly)
		}
		let right = UnsafeRawBufferPointer(start: CVPixelBufferGetBaseAddress(rhs.imageBuffer), count: CVPixelBufferGetDataSize(rhs.imageBuffer))

		return left.count == right.count && memcmp(left.baseAddress, right.baseAddress, min(left.count, right.count)) == 0
	}
}

class CoreAnimationAccelerator: UIView, ImageBufferAccelerator {
	let sublayer = CALayer()

	func setImageBuffer(_ imageBuffer: CVImageBuffer) {
		sublayer.contents = imageBuffer
	}

	override func layoutSubviews() {
		sublayer.frame = bounds
	}
}

extension CoreAnimationAccelerator {
	convenience init() {
		self.init(frame: .zero)
		layer.addSublayer(sublayer)
		sublayer.contentsGravity = .resizeAspect
	}
}

class MetalAccelerator: UIView, ImageBufferAccelerator {
	var imageBuffer: CVImageBuffer!
	var image: CIImage! {
		didSet {
			Task {
				await render()
			}
		}
	}

	override class var layerClass: AnyClass {
		CAMetalLayer.self
	}

	override func layoutSubviews() {
		layer.frame = bounds
		// If the view lays out again, refresh the Metal layer.
		Task {
			await render()
		}
	}

	var metalLayer: CAMetalLayer {
		layer as! CAMetalLayer
	}
	let colorSpace = CGColorSpaceCreateDeviceRGB()
	var commandQueue: MTLCommandQueue!
	var context: CIContext!

	actor Drawable {
		var layer: CAMetalLayer
		let queue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).\(_typeName(Drawable.self, qualified: false))")
		var lastContinuation: CheckedContinuation<CAMetalDrawable?, Never>?

		init(layer: CAMetalLayer) {
			self.layer = layer
		}

		func requestDrawable() async -> CAMetalDrawable? {
			let layer = self.layer
			lastContinuation?.resume(returning: nil)
			lastContinuation = nil
			return await withCheckedContinuation { continuation in
				lastContinuation = continuation
				queue.async {
					let drawable = layer.nextDrawable()
					Task {
						await self.yieldDrawable(drawable)
					}
				}
			}
		}

		func yieldDrawable(_ drawable: CAMetalDrawable?) {
			lastContinuation?.resume(returning: drawable)
			lastContinuation = nil
		}
	}
	var drawable: Drawable!

	func setImageBuffer(_ imageBuffer: CVImageBuffer) {
		if imageBuffer != self.imageBuffer {
			image = CIImage(cvImageBuffer: imageBuffer)
		}
	}

	func render() async {
		guard frame != .zero,
			let drawable = await drawable.requestDrawable()
		else {
			return
		}

		let texture = drawable.texture
		let commandBuffer = commandQueue.makeCommandBuffer()!

		let scale = min(metalLayer.drawableSize.width / image.extent.width, metalLayer.drawableSize.height / image.extent.height)
		let origin = CGPoint(x: (metalLayer.drawableSize.width - scale * image.extent.width) / 2, y: (metalLayer.drawableSize.height - scale * image.extent.height) / 2)
		let scaled =
			image
			.transformed(by: image.orientationTransform(for: .downMirrored))
			.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
			.transformed(by: .init(translationX: origin.x, y: origin.y))

		context.render(scaled, to: texture, commandBuffer: commandBuffer, bounds: .init(origin: .zero, size: metalLayer.drawableSize), colorSpace: colorSpace)

		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
}

extension MetalAccelerator {
	convenience init() {
		self.init(frame: .zero)
		drawable = .init(layer: metalLayer)
		metalLayer.isOpaque = false
		// FIXME: figure out how drawables are reserved
		// metalLayer.allowsNextDrawableTimeout = false
		metalLayer.contentsScale = contentScaleFactor

		metalLayer.framebufferOnly = false
		let device = metalLayer.preferredDevice!
		metalLayer.device = device
		commandQueue = device.makeCommandQueue()
		context = CIContext(mtlDevice: device)
	}
}

protocol ImageBufferAccelerator: UIView {
	func setImageBuffer(_ imageBuffer: CVImageBuffer)
}

struct AcceleratedImageBufferView<UIViewType: ImageBufferAccelerator>: UIViewRepresentable {
	let imageBuffer: CVImageBuffer

	func makeUIView(context: Context) -> UIViewType {
		return UIViewType()
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {
		uiView.setImageBuffer(imageBuffer)
	}
}
