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

struct AcceleratedImageBufferView: UIViewRepresentable {
	let imageBuffer: CVImageBuffer

	func makeUIView(context: Context) -> some UIView {
		let view = UIView()
		view.layer.contents = imageBuffer
		return view
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {
	}
}
