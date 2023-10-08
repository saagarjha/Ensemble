//
//  macOSInterface.swift
//  MacCast
//
//  Created by Saagar Jha on 10/9/23.
//

import CoreMedia
import Foundation

protocol macOSInterface {
	typealias M = macOSInterfaceMessages

	func _handshake(parameters: M.VisionOSHandshake.Request) async throws -> M.VisionOSHandshake.Reply
	func _windows(parameters: M.Windows.Request) async throws -> M.Windows.Reply
	func _windowPreview(parameters: M.WindowPreview.Request) async throws -> M.WindowPreview.Reply
	func _startCasting(parameters: M.StartCasting.Request) async throws -> M.StartCasting.Reply

}

struct Window: Codable, Identifiable {
	let windowID: UInt32
	let title: String
	let app: String

	var id: UInt32 {
		windowID
	}
}

enum macOSInterfaceMessages {
	struct VisionOSHandshake: Message {
		static let id = Messages.visionOSHandshake

		struct Request: Serializable, Codable {
			let version: Int
		}

		struct Reply: Serializable, Codable {
			let version: Int
		}
	}

	struct Windows: Message {
		static let id = Messages.windows

		typealias Request = SerializableVoid

		struct Reply: Serializable, Codable {
			let windows: [Window]
		}
	}

	struct WindowPreview: Message {
		static let id = Messages.windowPreview
		static let previewSize = CGSize(width: 600, height: 400)

		struct Request: Serializable, Codable {
			let windowID: UInt32
		}

		typealias Reply = CMSampleBuffer?
	}

	struct StartCasting: Message {
		static let id = Messages.startCasting

		struct Request: Serializable, Codable {
			let windowID: UInt32
		}

		typealias Reply = SerializableVoid
	}
}
