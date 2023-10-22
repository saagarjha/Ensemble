//
//  Local.swift
//  visionOS
//
//  Created by Saagar Jha on 10/9/23.
//

import Foundation

class Local: LocalInterface, visionOSInterface {
	var streams = [Window.ID: AsyncStream<Frame>.Continuation]()
	var children = [Window.ID: AsyncStream<[Window.ID]>.Continuation]()

	func handle(message: Messages, data: Data) async throws -> Data? {
		switch message {
			case .macOSHandshake:
				return try await _handshake(parameters: .decode(data)).encode()
			case .windowFrame:
				return try await _windowFrame(parameters: .decode(data)).encode()
			case .childWindows:
				return try await _childWindows(parameters: .decode(data)).encode()
			default:
				return nil
		}
	}

	func _handshake(parameters: M.MacOSHandshake.Request) async throws -> M.MacOSHandshake.Reply {
		return .init(version: Messages.version)
	}

	func _windowFrame(parameters: M.WindowFrame.Request) async throws -> M.WindowFrame.Reply {
		let stream = streams[parameters.windowID]!
		stream.yield(parameters.frame)
		return .init()
	}

	func _childWindows(parameters: M.ChildWindows.Request) async throws -> M.ChildWindows.Reply {
		let stream = children[parameters.parent]!
		stream.yield(parameters.children)
		return .init()
	}
}
