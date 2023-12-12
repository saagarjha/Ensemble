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

	let eventView = EventView()

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
			.onAppear {
				eventView.view.becomeFirstResponder()
			}
			.overlay {
				eventView
					.frame(width: actual.width, height: actual.height)
					.task {
						do {
							for await location in eventView.coordinator.hoverStream {
								_ = try await remote._mouseMoved(parameters: .init(windowID: window.windowID, x: location.x / actual.width, y: location.y / actual.height))
							}
						} catch {}
					}
					.task {
						do {
							for await translation in eventView.coordinator.panStream {
								_ = try await remote._scrolled(parameters: .init(windowID: window.windowID, x: translation.x, y: translation.y))
							}
						} catch {}
					}
					.task {
						do {
							for await (key, down) in eventView.view.keyStream {
								_ = try await remote._typed(parameters: .init(windowID: window.windowID, key: key, down: down))
							}
						} catch {}
					}
					.onTapGesture { location in
						eventView.view.becomeFirstResponder()
						Task {
							_ = try await remote._clicked(parameters: .init(windowID: window.windowID, x: location.x / actual.width, y: location.y / actual.height))
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
