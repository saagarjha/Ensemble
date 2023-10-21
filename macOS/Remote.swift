//
//  Remote.swift
//  macOS
//
//  Created by Saagar Jha on 10/9/23.
//

import AppleConnect
import CoreGraphics
import CoreMedia

struct Remote: visionOSInterface {
	let connection: Multiplexer

	init(connection: Connection) {
		let local = Local()
		self.connection = Multiplexer(connection: connection, localInterface: local)
		local.remote = self
	}

	func handshake() async throws -> Bool {
		try await _handshake(parameters: .init(version: Messages.version)).version == Messages.version
	}

	func _handshake(parameters: M.MacOSHandshake.Request) async throws -> M.MacOSHandshake.Reply {
		try await M.MacOSHandshake.send(parameters, through: connection)
	}

	func windowFrame(forWindowID windowID: CGWindowID, frame: CMSampleBuffer) async throws {
		_ = try await _windowFrame(parameters: .init(windowID: windowID, frame: frame))
	}

	func _windowFrame(parameters: M.WindowFrame.Request) async throws -> M.WindowFrame.Reply {
		try await M.WindowFrame.send(parameters, through: connection)
	}

	func childWindows(parent: CGWindowID, children: [CGWindowID]) async throws {
		_ = try await _childWindows(parameters: .init(parent: parent, children: children))
	}

	func _childWindows(parameters: M.ChildWindows.Request) async throws -> M.ChildWindows.Reply {
		try await M.ChildWindows.send(parameters, through: connection)
	}
}
