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
	var frame: Frame?

	let decoder = VideoDecoder()

	var body: some View {
		Group {
			if let frame {
				FrameView(frame: frame)
			} else {
				Text("Loading…")
			}
		}
		.task {
			do {
				for await frame in try await remote.startCasting(for: window.windowID) {
					self.frame = frame
				}
			} catch {}
		}
	}
}
