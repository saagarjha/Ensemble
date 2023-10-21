//
//  ContentView.swift
//  MacCast
//
//  Created by Saagar Jha on 10/8/23.
//

import AppleConnect
import SwiftUI

struct ContentView: View {
	var remote: Remote

	@Binding
	var selectedWindow: Window?

	@Environment(\.openWindow) private var openWindow

	var body: some View {
		Group {
			if let selectedWindow {
				RootWindowView(remote: remote, window: selectedWindow)
			} else {
				WindowPickerView(remote: remote, selectedWindow: $selectedWindow)
			}
		}
		.toolbar {
			ToolbarItem(placement: .bottomOrnament) {
				Button(action: {
					openWindow(id: "window")
				}) {
					Image(systemName: "plus")
				}
			}
		}
	}
}
