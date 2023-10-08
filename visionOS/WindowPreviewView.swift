//
//  WindowPreviewView.swift
//  visionOS
//
//  Created by Saagar Jha on 10/10/23.
//

import SwiftUI

struct WindowPreviewView: View {
	let remote: Remote
	let window: Window

	@Binding
	var selectedWindow: Window?

	@State
	var preview: CVImageBuffer?

	var body: some View {
		Button(action: {
			selectedWindow = window
		}) {
			VStack(alignment: .leading) {
				let size = macOSInterface.M.WindowPreview.previewSize
				Group {
					if let preview {
						ImageBufferView(imageBuffer: preview)
					} else {
						ProgressView {
							Text("Loading Preview…")
						}
					}
				}.frame(width: size.width, height: size.height)
				Text(window.app)
					.font(.title)
					.lineLimit(1)
				Text(window.title)
					.lineLimit(1)
			}
		}
		.buttonBorderShape(.roundedRectangle)
		.task {
			do {
				guard let preview = try await remote.windowPreview(forWindowID: window.id) else {
					return
				}
				self.preview = try await VideoDecoder.decode(image: preview)
			} catch {}
		}
	}
}
