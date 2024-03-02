//
//  macOSInterface.swift
//  Shared
//
//  Created by Saagar Jha on 10/9/23.
//

import CoreMedia
import CryptoKit
import Foundation

protocol macOSInterface {
	typealias M = macOSInterfaceMessages

	func _handshake(parameters: M.VisionOSHandshake.Request) async throws -> M.VisionOSHandshake.Reply
	func _windows(parameters: M.Windows.Request) async throws -> M.Windows.Reply
	func _windowPreview(parameters: M.WindowPreview.Request) async throws -> M.WindowPreview.Reply
	func _startCasting(parameters: M.StartCasting.Request) async throws -> M.StartCasting.Reply
	func _stopCasting(parameters: M.StopCasting.Request) async throws -> M.StopCasting.Reply
	func _windowMask(parameters: M.WindowMask.Request) async throws -> M.WindowMask.Reply
	func _startWatchingForChildWindows(parameters: M.StartWatchingForChildWindows.Request) async throws -> M.StartWatchingForChildWindows.Reply
	func _stopWatchingForChildWindows(parameters: M.StopWatchingForChildWindows.Request) async throws -> M.StopWatchingForChildWindows.Reply
	func _mouseMoved(parameters: M.MouseMoved.Request) async throws -> M.MouseMoved.Reply
	func _clicked(parameters: M.Clicked.Request) async throws -> M.Clicked.Reply
	func _scrollBegan(parameters: M.ScrollBegan.Request) async throws -> M.ScrollBegan.Reply
	func _scrollChanged(parameters: M.ScrollChanged.Request) async throws -> M.ScrollChanged.Reply
	func _scrollEnded(parameters: M.ScrollEnded.Request) async throws -> M.ScrollEnded.Reply
	func _dragBegan(parameters: M.DragBegan.Request) async throws -> M.DragBegan.Reply
	func _dragChanged(parameters: M.DragChanged.Request) async throws -> M.DragChanged.Reply
	func _dragEnded(parameters: M.DragEnded.Request) async throws -> M.DragEnded.Reply
	func _typed(parameters: M.Typed.Request) async throws -> M.Typed.Reply
	func _appIcon(parameters: M.AppIcon.Request) async throws -> M.AppIcon.Reply
}

struct Window: Codable, Identifiable {
	let windowID: UInt32
	let title: String?
	let app: String
	let frame: CGRect
	let windowLayer: Int

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
			let name: String
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
			let windowID: Window.ID
		}

		typealias Reply = Frame?
	}

	struct StartCasting: Message {
		static let id = Messages.startCasting

		struct Request: Serializable, Codable {
			let windowID: Window.ID
		}

		typealias Reply = SerializableVoid
	}

	struct StopCasting: Message {
		static let id = Messages.stopCasting

		struct Request: Serializable, Codable {
			let windowID: Window.ID
		}

		typealias Reply = SerializableVoid
	}

	struct WindowMask: Message {
		static let id = Messages.windowMask

		struct Request: Serializable, Codable {
			let windowID: Window.ID
			let hash: Data
		}

		typealias Reply = SerializableVoid
	}

	struct StartWatchingForChildWindows: Message {
		static let id = Messages.startWatchingForChildWindows

		struct Request: Serializable, Codable {
			let windowID: Window.ID
		}

		typealias Reply = SerializableVoid
	}

	struct StopWatchingForChildWindows: Message {
		static let id = Messages.stopWatchingForChildWindows

		struct Request: Serializable, Codable {
			let windowID: Window.ID
		}

		typealias Reply = SerializableVoid
	}

	struct MouseMoved: Message {
		static let id = Messages.mouseMoved

		struct Request: Serializable, Codable {
			let windowID: Window.ID
			let x: CGFloat
			let y: CGFloat
		}

		typealias Reply = SerializableVoid
	}

	struct Clicked: Message {
		static let id = Messages.clicked

		struct Request: Serializable, Codable {
			let windowID: Window.ID
			let x: CGFloat
			let y: CGFloat
		}

		typealias Reply = SerializableVoid
	}

	struct ScrollBegan: Message {
		static let id = Messages.scrollBegan

		struct Request: Serializable, Codable {
			let windowID: Window.ID
		}

		typealias Reply = SerializableVoid
	}

	struct ScrollChanged: Message {
		static let id = Messages.scrollChanged

		struct Request: Serializable, Codable {
			let windowID: Window.ID
			let x: CGFloat
			let y: CGFloat
		}

		typealias Reply = SerializableVoid
	}

	struct ScrollEnded: Message {
		static let id = Messages.scrollEnded

		struct Request: Serializable, Codable {
			let windowID: Window.ID
		}

		typealias Reply = SerializableVoid
	}

	struct DragBegan: Message {
		static let id = Messages.dragBegan

		struct Request: Serializable, Codable {
			let windowID: Window.ID
			let x: CGFloat
			let y: CGFloat
		}

		typealias Reply = SerializableVoid
	}

	struct DragChanged: Message {
		static let id = Messages.dragChanged

		struct Request: Serializable, Codable {
			let windowID: Window.ID
			let x: CGFloat
			let y: CGFloat
		}

		typealias Reply = SerializableVoid
	}

	struct DragEnded: Message {
		static let id = Messages.dragEnded

		struct Request: Serializable, Codable {
			let windowID: Window.ID
			let x: CGFloat
			let y: CGFloat
		}

		typealias Reply = SerializableVoid
	}

	struct Typed: Message {
		static let id = Messages.typed

		struct Request: Serializable, Codable {
			let windowID: Window.ID

			let key: Key
			let down: Bool
		}

		typealias Reply = SerializableVoid
	}

	struct AppIcon: Message {
		static let id = Messages.appIcon

		struct Request: Serializable, Codable {
			let windowID: Window.ID
			let size: CGSize
		}

		struct Reply: Serializable {
			let image: Data

			func encode() -> Data {
				image
			}

			static func decode(_ data: Data) -> Self {
				.init(image: data)
			}
		}
	}
}
