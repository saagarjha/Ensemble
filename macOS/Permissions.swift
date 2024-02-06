//
//  Permissions.swift
//  macOS
//
//  Created by Saagar Jha on 2/5/24.
//

import AppKit

enum Permission: CaseIterable, Identifiable {
	case screenRecording
	case accesibility
	
	var name: String {
		switch self {
		case .screenRecording:
			return "Screen Recording"
		case .accesibility:
			return "Accessibility"
		}
	}
	
	var id: String {
		name
	}
	
	var reason: String {
		switch self {
		case .screenRecording:
			return "Provides access to critical functionality such as the ability to list windows and stream them."
		case .accesibility:
			return "Used to track certain window elements and synthesize input events to control your Mac remotely."
		}
	}
	
	var enabled: Bool {
		switch self {
		case .screenRecording:
			CGPreflightScreenCaptureAccess()
		case .accesibility:
			// CGPreflightPostEventAccess appears to be a cached value
			AXIsProcessTrusted()
		}
	}
	
	var requested: Bool {
		false
	}
	
	func request() {
		var result: Bool
		switch self {
		case .screenRecording:
			result = CGRequestScreenCaptureAccess()
		case .accesibility:
			result = CGRequestPostEventAccess()
		}
		
		if !result {
			backupRequest()
		}
	}
	
	func backupRequest() {
		let parameter: String
		switch self {
		case .screenRecording:
			parameter = "Privacy_ScreenCapture"
		case .accesibility:
			parameter = "Privacy_Accessibility"
		}
		NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?\(parameter)")!)

	}
}
