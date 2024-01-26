//
//  Local.swift
//  macOS
//
//  Created by Saagar Jha on 10/9/23.
//

import Accelerate
import CryptoKit
import Foundation
import SystemConfiguration

class Local: LocalInterface, macOSInterface {
	var remote: Remote!

	let screenRecorder = ScreenRecorder()
	let eventDispatcher = EventDispatcher()

	struct Mask {
		let mask: vImage.PixelBuffer<vImage.Planar8>
		let hash: SHA256Digest
		var acknowledged: Bool
	}

	actor Masks {
		var masks = [Window.ID: Mask]()

		func unmask(_ frame: inout Frame, for windowID: Window.ID) {
			switch masks[windowID] {
				case let .some(mask):
					let same = mask.mask.withUnsafeBufferPointer { oldMask in
						frame.mask.withUnsafeBufferPointer { newMask in
							memcmp(oldMask.baseAddress, newMask.baseAddress, min(oldMask.count, newMask.count)) == 0
						}
					}
					if !same {
						fallthrough
					}
				case nil:
					frame.mask.withUnsafeBufferPointer {
						masks[windowID] = Mask(mask: frame.mask, hash: SHA256.hash(data: $0), acknowledged: false)
					}
			}

			if let mask = masks[windowID], mask.acknowledged {
				frame.skipMask = true
			}
		}

		func remove(for windowID: Window.ID) {
			masks.removeValue(forKey: windowID)
		}

		func acknowledge(hash: Data, for windowID: Window.ID) {
			var mask = masks[windowID]!
			if Data(mask.hash) == hash {
				mask.acknowledged = true
			}
			masks[windowID] = mask
		}
	}
	let masks = Masks()

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
			case .windowMask:
				return try await _windowMask(parameters: .decode(data)).encode()
			case .startWatchingForChildWindows:
				return try await _startWatchingForChildWindows(parameters: .decode(data)).encode()
			case .stopWatchingForChildWindows:
				return try await _stopWatchingForChildWindows(parameters: .decode(data)).encode()
			case .mouseMoved:
				return try await _mouseMoved(parameters: .decode(data)).encode()
			case .clicked:
				return try await _clicked(parameters: .decode(data)).encode()
			case .scrollBegan:
				return try await _scrollBegan(parameters: .decode(data)).encode()
			case .scrollChanged:
				return try await _scrollChanged(parameters: .decode(data)).encode()
			case .scrollEnded:
				return try await _scrollEnded(parameters: .decode(data)).encode()
			case .dragBegan:
				return try await _dragBegan(parameters: .decode(data)).encode()
			case .dragChanged:
				return try await _dragChanged(parameters: .decode(data)).encode()
			case .dragEnded:
				return try await _dragEnded(parameters: .decode(data)).encode()
			case .typed:
				return try await _typed(parameters: .decode(data)).encode()
			default:
				return nil
		}
	}

	func _handshake(parameters: M.VisionOSHandshake.Request) async throws -> M.VisionOSHandshake.Reply {
		return .init(version: Messages.version, name: SCDynamicStoreCopyComputerName(nil, nil)! as String)
	}

	func _windows(parameters: M.Windows.Request) async throws -> M.Windows.Reply {
		return try await .init(
			windows: screenRecorder.windows.compactMap {
				guard let application = $0.owningApplication?.applicationName,
					$0.isOnScreen
				else {
					return nil
				}
				return Window(windowID: $0.windowID, title: $0.title, app: application, frame: $0.frame, windowLayer: $0.windowLayer)
			})
	}

	func _windowPreview(parameters: M.WindowPreview.Request) async throws -> M.WindowPreview.Reply {
		guard let window = try await screenRecorder.lookup(windowID: parameters.windowID),
			window.isOnScreen,
			let screenshot = try await screenRecorder.screenshot(window: window, size: M.WindowPreview.previewSize)
		else {
			return nil
		}

		return try await Frame(frame: screenshot)
	}

	func _startCasting(parameters: M.StartCasting.Request) async throws -> M.StartCasting.Reply {
		let window = try await screenRecorder.lookup(windowID: parameters.windowID)!
		let stream = try await screenRecorder.stream(window: window)

		Task {
			for await frame in stream where frame.imageBuffer != nil {
				Task {
					var frame = try await Frame(frame: frame)
					await masks.unmask(&frame, for: parameters.windowID)

					try await remote.windowFrame(forWindowID: parameters.windowID, frame: frame)
				}
			}
		}
		return .init()
	}

	func _stopCasting(parameters: M.StopCasting.Request) async throws -> M.StopCasting.Reply {
		await screenRecorder.stopStream(for: parameters.windowID)
		await masks.remove(for: parameters.windowID)
		return .init()
	}

	func _windowMask(parameters: M.WindowMask.Request) async throws -> M.WindowMask.Reply {
		await masks.acknowledge(hash: parameters.hash, for: parameters.windowID)
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

	func _mouseMoved(parameters: M.MouseMoved.Request) async throws -> M.MouseMoved.Reply {
		let window = try await screenRecorder.lookup(windowID: parameters.windowID)!
		await eventDispatcher.injectMouseMoved(to: .init(x: window.frame.minX + window.frame.width * parameters.x, y: window.frame.minY + window.frame.height * parameters.y))

		return .init()
	}

	func _clicked(parameters: M.Clicked.Request) async throws -> M.Clicked.Reply {
		let window = try await screenRecorder.lookup(windowID: parameters.windowID)!
		await eventDispatcher.injectClick(at: .init(x: window.frame.minX + window.frame.width * parameters.x, y: window.frame.minY + window.frame.height * parameters.y), count: parameters.count)
		return .init()
	}

	func _scrollBegan(parameters: M.ScrollBegan.Request) async throws -> M.ScrollBegan.Reply {
		await eventDispatcher.injectScrollBegan()

		return .init()
	}

	func _scrollChanged(parameters: M.ScrollChanged.Request) async throws -> M.ScrollChanged.Reply {
		await eventDispatcher.injectScrollChanged(translationX: parameters.x, translationY: parameters.y)

		return .init()
	}

	func _scrollEnded(parameters: M.ScrollEnded.Request) async throws -> M.ScrollEnded.Reply {
		await eventDispatcher.injectScrollEnded()

		return .init()
	}

	func _dragBegan(parameters: M.DragBegan.Request) async throws -> M.DragBegan.Reply {
		let window = try await screenRecorder.lookup(windowID: parameters.windowID)!
		await eventDispatcher.injectDragBegan(at: .init(x: window.frame.minX + window.frame.width * parameters.x, y: window.frame.minY + window.frame.height * parameters.y))

		return .init()
	}

	func _dragChanged(parameters: M.DragChanged.Request) async throws -> M.DragChanged.Reply {
		let window = try await screenRecorder.lookup(windowID: parameters.windowID)!
		await eventDispatcher.injectDragChanged(to: .init(x: window.frame.minX + window.frame.width * parameters.x, y: window.frame.minY + window.frame.height * parameters.y))

		return .init()
	}

	func _dragEnded(parameters: M.DragEnded.Request) async throws -> M.DragEnded.Reply {
		let window = try await screenRecorder.lookup(windowID: parameters.windowID)!
		await eventDispatcher.injectDragEnded(at: .init(x: window.frame.minX + window.frame.width * parameters.x, y: window.frame.minY + window.frame.height * parameters.y))

		return .init()
	}

	func _typed(parameters: M.Typed.Request) async throws -> M.Typed.Reply {
		await eventDispatcher.injectKey(key: parameters.key, down: parameters.down)

		return .init()
	}
}
