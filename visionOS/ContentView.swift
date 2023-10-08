//
//  ContentView.swift
//  MacCast
//
//  Created by Saagar Jha on 10/8/23.
//

import AppleConnect
import SwiftUI

struct ContentView: View {
	@State
	var remote: Remote?

	@State
	var selectedWindow: Window?

	var body: some View {
		if let remote {
			if let selectedWindow {
				WindowView(remote: remote, window: selectedWindow)
			} else {
				WindowPickerView(remote: remote, selectedWindow: $selectedWindow)
			}
		} else {
			ConnectionView(remote: $remote)
		}
	}
}

#Preview(windowStyle: .automatic) {
	ContentView()
}
