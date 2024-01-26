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

	let eventView = EventView()
	let decoder = VideoDecoder()

	var body: some View {
		Group {
			if let frame {
				GeometryReader { geometry in
					FrameView(frame: frame)
						.overlay {
							eventView
								.task {
									do {
										for await event in eventView.coordinator.scrollStream {
											switch event {
												case .began:
													_ = try await remote._scrollBegan(parameters: .init(windowID: window.windowID))
												case .changed(let translation):
													_ = try await remote._scrollChanged(parameters: .init(windowID: window.windowID, x: translation.x, y: translation.y))
												case .ended:
													_ = try await remote._scrollEnded(parameters: .init(windowID: window.windowID))
											}
										}
									} catch {}
								}
								.task {
									do {
										for await event in eventView.coordinator.dragStream {
											switch event {
												case .began(let translation):
													_ = try await remote._dragBegan(parameters: .init(windowID: window.windowID, x: translation.x, y: translation.y))
												case .changed(let translation):
													_ = try await remote._dragChanged(parameters: .init(windowID: window.windowID, x: translation.x, y: translation.y))
												case .ended(let translation):
													_ = try await remote._dragEnded(parameters: .init(windowID: window.windowID, x: translation.x, y: translation.y))
											}
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
						}
						.onTapGesture(count: 3) {
							click(at: $0, in: geometry.size, count: 3)
						}
						// FIXME: This isn't detected
						.onTapGesture(count: 2) {
							click(at: $0, in: geometry.size, count: 2)
						}
						.onTapGesture {
							click(at: $0, in: geometry.size, count: 1)
						}
						.onContinuousHover(coordinateSpace: .local) {
							switch $0 {
								case .active(let location):
									Task {
										do {
											_ = try await remote._mouseMoved(parameters: .init(windowID: window.windowID, x: location.x / geometry.size.width, y: location.y / geometry.size.height))
										} catch {}
									}
								default:
									break
							}
						}
						.onAppear {
							eventView.view.becomeFirstResponder()
						}
				}
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

	func click(at location: CGPoint, in size: CGSize, count: Int) {
		eventView.view.becomeFirstResponder()
		Task {
			_ = try await remote._clicked(parameters: .init(windowID: window.windowID, x: location.x / size.width, y: location.y / size.height, count: count))
		}
	}
}
