//
//  RootWindowView.swift
//  visionOS
//
//  Created by Saagar Jha on 10/21/23.
//

import AVFoundation
import SwiftUI

struct RootWindowView: View {
	let remote: Remote
	let window: Window


	@State
	var children = [Window]()

	var body: some View {
		GeometryReader { geometry in
			let actual = AVMakeRect(aspectRatio: window.frame.size, insideRect: CGRect(origin: .zero, size: geometry.size)).size

			ZStack {
				WindowView(remote: remote, window: window)
				ForEach(children) { child in
					let width = child.frame.width / window.frame.width * actual.width
					let height = child.frame.height / window.frame.height * actual.height
					let x = (child.frame.minX - window.frame.minX + child.frame.width / 2) / window.frame.width * actual.width / geometry.size.width + (geometry.size.width - actual.width) / 2 / geometry.size.width
					let y = (child.frame.minY - window.frame.minY + child.frame.height / 2) / window.frame.height * actual.height / geometry.size.height + (geometry.size.height - actual.height) / 2 / geometry.size.height

					Color.clear
						.ornament(attachmentAnchor: .scene(.init(x: x, y: y))) {
							WindowView(remote: remote, window: child)
								.frame(width: width, height: height)
						}
				}
			}
		}
		.task {
			do {
				for await children in try await remote.children(of: window.id) {
					let windows = try await remote.windows
					self.children = children.compactMap { child in
						windows.first {
							$0.id == child
						}
					}
				}
			} catch {}
		}
	}
}
