//
//  Local.swift
//  macOS
//
//  Created by Saagar Jha on 10/9/23.
//

import AVFoundation
import Foundation
import ScreenCaptureKit

class Local: LocalInterface, macOSInterface {
	var remote: Remote!

	struct Stream {
		class Output: NSObject, SCStreamOutput {
			let continuation: AsyncStream<CMSampleBuffer>.Continuation

			init(continuation: AsyncStream<CMSampleBuffer>.Continuation) {
				self.continuation = continuation
			}

			func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
				continuation.yield(sampleBuffer)
			}
		}

		let (frames, continuation) = AsyncStream.makeStream(of: CMSampleBuffer.self, bufferingPolicy: .bufferingNewest(1))
		let output: Output
		let stream: SCStream

		init(windowID: CGWindowID) async throws {
			let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
			let window = content.windows.first {
				$0.windowID == windowID
			}!
			let filter = SCContentFilter(desktopIndependentWindow: window)

			let configuration = SCStreamConfiguration()
			configuration.width = Int(window.frame.width * CGFloat(filter.pointPixelScale))
			configuration.height = Int(window.frame.height * CGFloat(filter.pointPixelScale))

			stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
			output = Output(continuation: continuation)
			try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: nil)
			try await stream.startCapture()
		}
	}

	var streams = [Stream]()

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
			default:
				return nil
		}
	}

	func _handshake(parameters: M.VisionOSHandshake.Request) async throws -> M.VisionOSHandshake.Reply {
		return .init(version: Messages.version)
	}

	func _windows(parameters: M.Windows.Request) async throws -> M.Windows.Reply {
		let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
		return .init(
			windows: content.windows.compactMap {
				guard let title = $0.title,
					let application = $0.owningApplication?.applicationName,
					$0.isOnScreen
				else {
					return nil
				}
				return Window(windowID: $0.windowID, title: title, app: application)
			})
	}

	func _windowPreview(parameters: M.WindowPreview.Request) async throws -> M.WindowPreview.Reply {
		let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
		guard let window = content.windows.first(where: { $0.windowID == parameters.windowID }),
			window.isOnScreen
		else {
			return nil
		}
		let filter = SCContentFilter(desktopIndependentWindow: window)
		let configuration = SCStreamConfiguration()
		let size = AVMakeRect(aspectRatio: window.frame.size, insideRect: CGRect(origin: .zero, size: M.WindowPreview.previewSize)).size
		configuration.width = Int(size.width)
		configuration.height = Int(size.height)
		guard let screenshot = try? await SCScreenshotManager.captureSampleBuffer(contentFilter: filter, configuration: configuration) else {
			return nil
		}
		return try await VideoEncoder.encode(image: screenshot)
	}

	func _startCasting(parameters: M.StartCasting.Request) async throws -> M.StartCasting.Reply {
		let stream = try await Stream(windowID: parameters.windowID)
		streams.append(stream)
		let encoder = VideoEncoder()
		Task {
			for await frame in stream.frames where frame.imageBuffer != nil {
				try encoder.encode(frame)
			}
		}
		Task {
			for try await frame in encoder.frames {
				try await remote.windowFrame(forWindowID: parameters.windowID, frame: frame)
			}
		}
		return .init()
	}
}
