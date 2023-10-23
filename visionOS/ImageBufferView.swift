//
//  ImageBufferView.swift
//  visionOS
//
//  Created by Saagar Jha on 10/10/23.
//

import SwiftUI

struct ImageBufferView: View, Equatable {
	let imageBuffer: CVImageBuffer
	var enableAcceleration = true

	var body: some View {
		#if targetEnvironment(simulator)
			let simulator = true
		#else
			let simulator = false
		#endif
		if !simulator, enableAcceleration {
			AcceleratedImageBufferView(imageBuffer: imageBuffer)
		} else {
			let image = CIImage(cvImageBuffer: imageBuffer)
			let cgImage = CIContext().createCGImage(image, from: image.extent)!
			Image(uiImage: UIImage(cgImage: cgImage))
				.resizable()
				.aspectRatio(contentMode: .fit)
		}
	}

	static func == (lhs: Self, rhs: Self) -> Bool {
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

class LayerView: UIView {
	let sublayer = CALayer()

	override func layoutSubviews() {
		sublayer.frame = bounds
	}
}

extension LayerView {
	convenience init() {
		self.init(frame: .zero)
		layer.addSublayer(sublayer)
		sublayer.contentsGravity = .resizeAspect
	}
}

struct AcceleratedImageBufferView: UIViewRepresentable {
	let imageBuffer: CVImageBuffer

	func makeUIView(context: Context) -> LayerView {
		let view = LayerView()
		return view
	}

	func updateUIView(_ uiView: LayerView, context: Context) {
		uiView.sublayer.contents = imageBuffer
	}
}
