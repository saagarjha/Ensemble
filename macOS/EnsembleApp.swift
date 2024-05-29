//
//  EnsembleApp.swift
//  macOS
//
//  Created by Saagar Jha on 10/8/23.
//

import SwiftUI

@main
struct EnsembleApp: App {
	@Environment(\.openWindow)
	var openWindow

	@Preference(\.persistedHistoricalLogs)
	var persistedHistoricalLogs

	init() {
		Log.pruneLogs(count: persistedHistoricalLogs)
	}

	var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.windowResizability(.contentSize)
		.commands {
			CommandGroup(after: .help) {
				Divider()
				Button("Logs…") {
					openWindow(id: "logs")
				}
			}
		}

		SwiftUI.Window("Logs", id: "logs") {
			LogsView()
		}
	}
}
