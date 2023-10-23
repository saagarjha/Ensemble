//
//  ImageBufferView.swift
//  visionOS
//
//  Created by Saagar Jha on 10/10/23.
//

import SwiftUI

struct ImageBufferView: View {
	let imageBuffer: CVImageBuffer

	var body: some View {
		#if targetEnvironment(simulator)
			let image = CIImage(cvImageBuffer: imageBuffer)
			let cgImage = CIContext().createCGImage(image, from: image.extent)!
			Image(uiImage: UIImage(cgImage: cgImage))
				.resizable()
				.aspectRatio(contentMode: .fit)
		#else
			AcceleratedImageBufferView(imageBuffer: imageBuffer)
		#endif
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
