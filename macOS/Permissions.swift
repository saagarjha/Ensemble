//
//  Permissions.swift
//  macOS
//
//  Created by Saagar Jha on 2/5/24.
//

import AppKit

// Not really a list of permissions, and not really worth making an enum either.
// This really just exists to make some UI code a bit easier to write.
enum Permission: CaseIterable, Identifiable {
	case screenRecording
	case accesibility
	case helper

	var name: String {
		switch self {
			case .screenRecording:
				return "Screen Recording"
			case .accesibility:
				return "Accessibility"
			case .helper:
				return "Helper"
		}
	}

	var id: String {
		name
	}

	var reason: String {
		guard supported else {
			return "This feature is not supported on your Mac."
		}

		switch self {
			case .screenRecording:
				return "Provides access to critical functionality such as the ability to list windows and stream them."
			case .accesibility:
				return "Used to synthesize input events so your Mac can be controlled remotely from Apple Vision Pro."
			case .helper:
				return "Enables \(Bundle.main.name) to track certain window elements and interact with them reliably."
		}
	}

	var enabled: Bool {
		switch self {
			case .screenRecording:
				CGPreflightScreenCaptureAccess()
			case .accesibility:
				// CGPreflightPostEventAccess appears to be a cached value
				AXIsProcessTrusted()
			case .helper:
				(try? NSUserUnixTask(url: Self.helperScriptInstallLocation)) != nil
		}
	}

	var supported: Bool {
		switch self {
			case .screenRecording, .accesibility:
				return true
			case .helper:
				return sandbox_extension_consume != nil
		}
	}

	var prompt: String {
		guard supported else {
			return "Unsupported"
		}

		switch self {
			case .screenRecording, .accesibility:
				return enabled ? "Enabled!" : "Request…"
			case .helper:
				return enabled ? "Installed!" : "Install…"
		}
	}

	func request() {
		var result: Bool
		switch self {
			case .screenRecording:
				result = CGRequestScreenCaptureAccess()
			case .accesibility:
				result = CGRequestPostEventAccess()
			case .helper:
				result = false
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
			case .helper:
				NSWorkspace.shared.open(Permission.helperScriptInstallLocation.deletingLastPathComponent())
				NSWorkspace.shared.selectFile(Permission.helperScriptLocation.path, inFileViewerRootedAtPath: Self.helperScriptLocation.deletingLastPathComponent().path)
				return
		}
		NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?\(parameter)")!)
	}

	static func prewarmHelper() async -> Bool {
		guard let sandbox_extension_consume,
			let task = try? NSUserUnixTask(url: Self.helperScriptInstallLocation)
		else {
			return false
		}

		let pipe = Pipe()
		task.standardOutput = pipe.fileHandleForWriting
		guard (try? await task.execute(withArguments: nil)) != nil,
			let data = try? pipe.fileHandleForReading.readToEnd(),
			let sandboxExtension = String(data: data, encoding: .ascii),
			// Strip off the newline
			sandbox_extension_consume(String(sandboxExtension.dropLast())) >= 0
		else {
			return false
		}

		return true
	}

	static var helperScriptName: String {
		"\(Bundle.main.name.lowercased())_helper_v1.sh"
	}

	static var helperScriptLocation: URL {
		Bundle.main.sharedSupportURL!.appendingPathComponent(helperScriptName)
	}

	// This logs an annoying warning about being called on the main thread
	// (because it goes through SecTrustEvaluateIfNecessary) so only do it once
	static var applicationScripts = {
		try! FileManager.default.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
	}()

	static var helperScriptInstallLocation: URL {
		applicationScripts.appendingPathComponent(helperScriptName)
	}
}
