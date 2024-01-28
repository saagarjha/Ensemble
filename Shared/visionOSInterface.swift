//
//  visionOSInterface.swift
//  Shared
//
//  Created by Saagar Jha on 10/9/23.
//

import CoreMedia
import Foundation

protocol visionOSInterface {
	typealias M = visionOSMessages

	func _handshake(parameters: M.MacOSHandshake.Request) async throws -> M.MacOSHandshake.Reply
	func _windowFrame(parameters: M.WindowFrame.Request) async throws -> M.WindowFrame.Reply
	func _childWindows(parameters: M.ChildWindows.Request) async throws -> M.ChildWindows.Reply
}

enum visionOSMessages {
	struct MacOSHandshake: Message {
		static let id = Messages.macOSHandshake

		struct Request: Serializable, Codable {
			let version: Int
		}

		struct Reply: Serializable, Codable {
			let version: Int
			let name: String
		}
	}

	struct WindowFrame: Message {
		static let id = Messages.windowFrame

		struct Request: Serializable {
			let windowID: Window.ID
			let frame: Frame

			func encode() async throws -> Data {
				return try await windowID.uleb128 + frame.encode()
			}

			static func decode(_ data: Data) async throws -> Self {
				var data = data
				return try await self.init(windowID: .init(uleb128: &data), frame: .decode(data))
			}
		}

		typealias Reply = SerializableVoid
	}

	struct ChildWindows: Message {
		static let id = Messages.childWindows

		struct Request: Serializable, Codable {
			let parent: Window.ID
			let children: [Window.ID]
		}

		typealias Reply = SerializableVoid
	}
}
