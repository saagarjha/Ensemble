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
	var preview: Frame?

	var body: some View {
		Button(action: {
			selectedWindow = window
		}) {
			VStack(alignment: .leading) {
				let size = macOSInterface.M.WindowPreview.previewSize
				Group {
					if let preview {
						FrameView(frame: preview)
					} else {
						ProgressView {
							Text("Loading Preview…")
						}
					}
				}.frame(width: size.width, height: size.height)
				Text(window.app)
					.font(.title)
					.lineLimit(1)
				Text(window.title!)
					.lineLimit(1)
			}
		}
		.buttonBorderShape(.roundedRectangle)
		.task {
			do {
				// while true {
				guard let preview = try await remote.windowPreview(for: window.id) else {
					return
				}
				self.preview = preview
				// try await Task.sleep(for: .seconds(1))
				// }
			} catch {}
		}
	}
}
