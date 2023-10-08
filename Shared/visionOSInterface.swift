//
//  visionOSInterface.swift
//  MacCast
//
//  Created by Saagar Jha on 10/9/23.
//

import CoreMedia
import Foundation

protocol visionOSInterface {
	typealias M = visionOSMessages

	func _handshake(parameters: M.MacOSHandshake.Request) async throws -> M.MacOSHandshake.Reply
	func _windowFrame(parameters: M.WindowFrame.Request) async throws -> M.WindowFrame.Reply
}

enum visionOSMessages {
	struct MacOSHandshake: Message {
		static let id = Messages.macOSHandshake

		struct Request: Serializable, Codable {
			let version: Int
		}

		struct Reply: Serializable, Codable {
			let version: Int
		}
	}

	struct WindowFrame: Message {
		static let id = Messages.windowFrame

		struct Request: Serializable {
			let windowID: UInt32
			let frame: CMSampleBuffer

			func encode() throws -> Data {
				return try windowID.uleb128 + frame.encode()
			}

			static func decode(_ data: Data) throws -> Self {
				var data = data
				return try self.init(windowID: .init(uleb128: &data), frame: .decode(data))
			}
		}

		typealias Reply = SerializableVoid
	}
}
