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

	func windowPreview(forWindowID windowID: UInt32) async throws -> CMSampleBuffer? {
		try await _windowPreview(parameters: .init(windowID: windowID))
	}

	func _windowPreview(parameters: M.WindowPreview.Request) async throws -> M.WindowPreview.Reply {
		try await M.WindowPreview.send(parameters, through: connection)
	}

	func startCasting(forWindowID windowID: UInt32) async throws -> AsyncStream<CMSampleBuffer> {
		let (stream, continuation) = AsyncStream.makeStream(of: CMSampleBuffer.self)
		local.streams[windowID] = continuation
		_ = try await _startCasting(parameters: .init(windowID: windowID))
		return stream
	}

	func _startCasting(parameters: M.StartCasting.Request) async throws -> M.StartCasting.Reply {
		try await M.StartCasting.send(parameters, through: connection)
	}
}
