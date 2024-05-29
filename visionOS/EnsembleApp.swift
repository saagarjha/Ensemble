//
//  EnsembleApp.swift
//  visionOS
//
//  Created by Saagar Jha on 10/8/23.
//

import SwiftUI

@main
struct EnsembleApp: App {
	@State
	var remote: Remote?

	// This needs to be available "immedidately" because when the binding
	// updates it will consult this list, and @State will have a stale value.
	class _State {
		var windows = [Window.ID: Window]()
	}
	let state = _State()

	@Preference(\.persistedHistoricalLogs)
	var persistedHistoricalLogs

	init() {
		Log.pruneLogs(count: persistedHistoricalLogs)
	}

	var body: some Scene {
		WindowGroup("Window", id: "window", for: Window.ID.self) { $window in
			if let remote {
				let selectedWindow = Binding(
					get: {
						$window.wrappedValue.flatMap {
							state.windows[$0]
						}
					},
					set: {
						if let window = $0 {
							state.windows[window.id] = window
							$window.wrappedValue = window.id
						}
					})

				ContentView(remote: remote, selectedWindow: selectedWindow)
			} else {
				ConnectionView(remote: $remote)
			}
		}
		.windowStyle(.plain)
		.windowResizability(.contentSize)

		WindowGroup("Logs", id: "logs") {
			LogsView()
		}
	}
}
