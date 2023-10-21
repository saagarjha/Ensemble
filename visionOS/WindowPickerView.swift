//
//  WindowPickerView.swift
//  visionOS
//
//  Created by Saagar Jha on 10/10/23.
//

import SwiftUI

struct WindowPickerView: View {
	let remote: Remote

	@State
	var windows: [Window]?

	@Binding
	var selectedWindow: Window?

	var body: some View {
		NavigationStack {
			if let windows {
				ScrollView {
					LazyVGrid(
						columns: [GridItem(), GridItem()],
						spacing: 20,
						content: {
							ForEach(windows) { window in
								WindowPreviewView(remote: remote, window: window, selectedWindow: $selectedWindow)
							}
						}
					)
					.padding(20)
				}
				.navigationTitle("Select a window.")
			} else {
				Text("Loading windows…")
					.task {
						do {
							windows = try await remote.windows.filter {
								!($0.title ?? "").isEmpty
							}
						} catch {}
					}
			}
		}
	}
}
