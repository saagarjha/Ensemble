//
//  Remote.swift
//  visionOS
//
//  Created by Saagar Jha on 10/9/23.
//

import AppleConnect
import CoreMedia

struct Remote: macOSInterface {
	let connection: Multiplexer
	let local: Local

	init(connection: Connection) {
		local = Local()
		self.connection = Multiplexer(connection: connection, localInterface: local)
	}

	func handshake() async throws -> Bool {
		try await _handshake(parameters: .init(version: Messages.version)).version == Messages.version
	}

	func _handshake(parameters: M.VisionOSHandshake.Request) async throws -> M.VisionOSHandshake.Reply {
		try await M.VisionOSHandshake.send(parameters, through: connection)
	}

	var windows: [Window] {
		get async throws {
			try await _windows(parameters: .init()).windows
		}
	}

	func _windows(parameters: M.Windows.Request) async throws -> M.Windows.Reply {
		try await M.Windows.send(parameters, through: connection)
	}

	func windowPreview(for windowID: Window.ID) async throws -> Frame? {
		try await _windowPreview(parameters: .init(windowID: windowID))
	}

	func _windowPreview(parameters: M.WindowPreview.Request) async throws -> M.WindowPreview.Reply {
		try await M.WindowPreview.send(parameters, through: connection)
	}

	func startCasting(for windowID: Window.ID) async throws -> AsyncStream<Frame> {
		let (stream, continuation) = AsyncStream.makeStream(of: Frame.self)
		local.streams[windowID] = continuation
		continuation.onTermination = { _ in
			Task {
				try await _stopCasting(parameters: .init(windowID: windowID))
			}
		}
		_ = try await _startCasting(parameters: .init(windowID: windowID))
		return stream
	}

	func _startCasting(parameters: M.StartCasting.Request) async throws -> M.StartCasting.Reply {
		try await M.StartCasting.send(parameters, through: connection)
	}

	func _stopCasting(parameters: M.StopCasting.Request) async throws -> M.StopCasting.Reply {
		try await M.StopCasting.send(parameters, through: connection)
	}

	func children(of windowID: Window.ID) async throws -> AsyncStream<[Window.ID]> {
		let (stream, continuation) = AsyncStream.makeStream(of: [Window.ID].self)
		local.children[windowID] = continuation
		continuation.onTermination = { _ in
			Task {
				try await _stopWatchingForChildWindows(parameters: .init(windowID: windowID))
			}
		}
		_ = try await _startWatchingForChildWindows(parameters: .init(windowID: windowID))
		return stream
	}

	func _startWatchingForChildWindows(parameters: M.StartWatchingForChildWindows.Request) async throws -> M.StartWatchingForChildWindows.Reply {
		try await M.StartWatchingForChildWindows.send(parameters, through: connection)
	}

	func _stopWatchingForChildWindows(parameters: M.StopWatchingForChildWindows.Request) async throws -> M.StopWatchingForChildWindows.Reply {
		try await M.StopWatchingForChildWindows.send(parameters, through: connection)
	}
}
