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
	var name: String!

	init(connection: Connection) {
		local = Local()
		self.connection = Multiplexer(connection: connection, localInterface: local)
		local.remote = self
	}

	mutating func handshake() async throws -> Bool {
		let handshake = try await _handshake(parameters: .init(version: Messages.version))
		guard handshake.version == Messages.version else {
			return false
		}
		name = handshake.name
		return true
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
		let (stream, continuation) = AsyncStream.makeStream(of: Frame.self, bufferingPolicy: .bufferingNewest(1))
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

	func _windowMask(parameters: M.WindowMask.Request) async throws -> M.WindowMask.Reply {
		try await M.WindowMask.send(parameters, through: connection)
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

	func _mouseMoved(parameters: M.MouseMoved.Request) async throws -> M.MouseMoved.Reply {
		try await M.MouseMoved.send(parameters, through: connection)
	}

	func _clicked(parameters: M.Clicked.Request) async throws -> M.Clicked.Reply {
		try await M.Clicked.send(parameters, through: connection)
	}

	func _scrollBegan(parameters: M.ScrollBegan.Request) async throws -> M.ScrollBegan.Reply {
		try await M.ScrollBegan.send(parameters, through: connection)
	}

	func _scrollChanged(parameters: M.ScrollChanged.Request) async throws -> M.ScrollChanged.Reply {
		try await M.ScrollChanged.send(parameters, through: connection)
	}

	func _scrollEnded(parameters: M.ScrollEnded.Request) async throws -> M.ScrollEnded.Reply {
		try await M.ScrollEnded.send(parameters, through: connection)
	}

	func _dragBegan(parameters: M.DragBegan.Request) async throws -> M.DragBegan.Reply {
		try await M.DragBegan.send(parameters, through: connection)
	}

	func _dragChanged(parameters: M.DragChanged.Request) async throws -> M.DragChanged.Reply {
		try await M.DragChanged.send(parameters, through: connection)
	}

	func _dragEnded(parameters: M.DragEnded.Request) async throws -> M.DragEnded.Reply {
		try await M.DragEnded.send(parameters, through: connection)
	}

	func _typed(parameters: M.Typed.Request) async throws -> M.Typed.Reply {
		try await M.Typed.send(parameters, through: connection)
	}
}
