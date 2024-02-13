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
	@State
	var filter: String = ""

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
							let filteredWindows = windows.filter {
								filter.isEmpty || $0.app.localizedStandardContains(filter) || $0.title?.localizedStandardContains(filter) ?? false
							}
							ForEach(filteredWindows) { window in
								WindowPreviewView(remote: remote, window: window, selectedWindow: $selectedWindow)
							}
						}
					)
					.padding(20)
				}
				.navigationTitle("Select a window.")
				.searchable(text: $filter)
			} else {
				Text("Loading windows…")
			}
		}
		.task {
			do {
				while true {
					windows = try await remote.windows.filter {
						!($0.title?.isEmpty ?? true) && $0.windowLayer == 0 /* NSWindow.Level.normal */
					}.sorted {
						$0.windowID < $1.windowID
					}
					try await Task.sleep(for: .seconds(1))
				}
			} catch {}
		}
	}
}
