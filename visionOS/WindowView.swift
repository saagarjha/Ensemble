//
//  WindowView.swift
//  visionOS
//
//  Created by Saagar Jha on 10/10/23.
//

import SwiftUI

struct WindowView: View {
	let remote: Remote
	let window: Window

	@State
	var frame: CVImageBuffer?

	let decoder = VideoDecoder()

	var body: some View {
		Group {
			if let frame {
				ImageBufferView(imageBuffer: frame)
			} else {
				Text("Connected")
			}
		}
		.task {
			do {
				for await frame in try await remote.startCasting(for: window.windowID) {
					try decoder.decode(frame)
				}
			} catch {}
		}
		.task {
			do {
				for try await frame in decoder.frames {
					self.frame = frame
				}
			} catch {}
		}
	}
}
