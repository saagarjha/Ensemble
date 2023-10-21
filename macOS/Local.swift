//
//  Local.swift
//  macOS
//
//  Created by Saagar Jha on 10/9/23.
//

import AVFoundation
import Foundation
import ScreenCaptureKit

class Local: LocalInterface, macOSInterface {
	var remote: Remote!

	let screenRecorder = ScreenRecorder()

	func handle(message: Messages, data: Data) async throws -> Data? {
		switch message {
			case .visionOSHandshake:
				return try await _handshake(parameters: .decode(data)).encode()
			case .windows:
				return try await _windows(parameters: .decode(data)).encode()
			case .windowPreview:
				return try await _windowPreview(parameters: .decode(data)).encode()
			case .startCasting:
				return try await _startCasting(parameters: .decode(data)).encode()
			case .stopCasting:
				return try await _stopCasting(parameters: .decode(data)).encode()
			case .startWatchingForChildWindows:
				return try await _startWatchingForChildWindows(parameters: .decode(data)).encode()
			case .stopWatchingForChildWindows:
				return try await _stopWatchingForChildWindows(parameters: .decode(data)).encode()
			default:
				return nil
		}
	}

	func _handshake(parameters: M.VisionOSHandshake.Request) async throws -> M.VisionOSHandshake.Reply {
		return .init(version: Messages.version)
	}

	func _windows(parameters: M.Windows.Request) async throws -> M.Windows.Reply {
		return try await .init(
			windows: screenRecorder.windows.compactMap {
				guard let application = $0.owningApplication?.applicationName,
					$0.isOnScreen
				else {
					return nil
				}
				return Window(windowID: $0.windowID, title: $0.title, app: application, frame: $0.frame)
			})
	}

	func _windowPreview(parameters: M.WindowPreview.Request) async throws -> M.WindowPreview.Reply {
		guard let window = try await screenRecorder.lookup(windowID: parameters.windowID),
			window.isOnScreen,
			let screenshot = try await screenRecorder.screenshot(window: window, size: M.WindowPreview.previewSize)
		else {
			return nil
		}

		return try await VideoEncoder.encode(image: screenshot)
	}

	func _startCasting(parameters: M.StartCasting.Request) async throws -> M.StartCasting.Reply {
		let window = try await screenRecorder.lookup(windowID: parameters.windowID)!
		let stream = try await screenRecorder.stream(window: window)

		let encoder = VideoEncoder()
		Task {
			for await frame in stream where frame.imageBuffer != nil {
				try encoder.encode(frame)
			}
		}
		Task {
			for try await frame in encoder.frames {
				try await remote.windowFrame(forWindowID: parameters.windowID, frame: frame)
			}
		}
		return .init()
	}

	func _stopCasting(parameters: M.StopCasting.Request) async throws -> M.StopCasting.Reply {
		await screenRecorder.stopStream(for: parameters.windowID)
		return .init()
	}

	func _startWatchingForChildWindows(parameters: M.StartWatchingForChildWindows.Request) async throws -> M.StartWatchingForChildWindows.Reply {
		Task {
			for await children in await screenRecorder.watchForChildren(windowID: parameters.windowID) {
				try await remote.childWindows(parent: parameters.windowID, children: children)
			}
		}
		return .init()
	}

	func _stopWatchingForChildWindows(parameters: M.StopWatchingForChildWindows.Request) async throws -> M.StopWatchingForChildWindows.Reply {
		await screenRecorder.stopWatchingForChildren(windowID: parameters.windowID)
		return .init()
	}
}
