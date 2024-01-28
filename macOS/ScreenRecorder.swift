//
//  ScreenRecorder.swift
//  macOS
//
//  Created by Saagar Jha on 10/21/23.
//

import AVFoundation
import ScreenCaptureKit

actor ScreenRecorder {
	static let cacheDuration = Duration.seconds(1)

	var _windows = [CGWindowID: SCWindow]()
	var _lastWindowFetch = ContinuousClock.Instant.now.advanced(by: ScreenRecorder.cacheDuration * -2)

	func _updateWindows(force: Bool = false) async throws {
		guard ContinuousClock.Instant.now - _lastWindowFetch > Self.cacheDuration || force else {
			return
		}

		try await _windows = Dictionary(
			uniqueKeysWithValues: SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false).windows.map {
				($0.windowID, $0)
			})
		_lastWindowFetch = ContinuousClock.Instant.now
	}

	var windows: [SCWindow] {
		get async throws {
			try await _updateWindows()
			return Array(_windows.values)
		}
	}

	func lookup(windowID: CGWindowID) async throws -> SCWindow? {
		if let window = _windows[windowID] {
			return window
		} else {
			try await _updateWindows(force: true)
			return _windows[windowID]
		}
	}

	static func streamConfiguration() -> SCStreamConfiguration {
		let configuration = SCStreamConfiguration()
		configuration.pixelFormat = kCVPixelFormatType_32BGRA
		return configuration
	}

	func screenshot(window: SCWindow, size: CGSize) async throws -> CMSampleBuffer? {
		let filter = SCContentFilter(desktopIndependentWindow: window)
		let configuration = Self.streamConfiguration()
		let size = AVMakeRect(aspectRatio: window.frame.size, insideRect: CGRect(origin: .zero, size: size)).size
		configuration.width = Int(size.width)
		configuration.height = Int(size.height)
		configuration.captureResolution = .nominal
		configuration.showsCursor = false
		return try await SCScreenshotManager.captureSampleBuffer(contentFilter: filter, configuration: configuration)
	}

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

		init(window: SCWindow) async throws {
			let filter = SCContentFilter(desktopIndependentWindow: window)

			let configuration = ScreenRecorder.streamConfiguration()
			configuration.width = Int(window.frame.width * CGFloat(filter.pointPixelScale))
			configuration.height = Int(window.frame.height * CGFloat(filter.pointPixelScale))
			if #available(macOS 14.2, *) {
				configuration.includeChildWindows = SLSCopyAssociatedWindows == nil
			}
			configuration.showsCursor = false

			stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
			output = Output(continuation: continuation)
			try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: nil)
			try await stream.startCapture()
		}

		func stop() async {
			// This will throw an error if the window doesn't exist anymore
			try? await stream.stopCapture()
		}
	}

	var streams = [CGWindowID: Stream]()

	func stream(window: SCWindow) async throws -> AsyncStream<CMSampleBuffer> {
		let stream = try await Stream(window: window)
		streams[window.windowID] = stream
		return stream.frames
	}

	func stopStream(for windowID: CGWindowID) async {
		await streams.removeValue(forKey: windowID)!.stop()
	}

	var childObservers = Set<CGWindowID>()

	func watchForChildren(windowID: CGWindowID) -> AsyncStream<[CGWindowID]> {
		let (stream, continuation) = AsyncStream.makeStream(of: [CGWindowID].self)
		childObservers.insert(windowID)
		Task {
			while childObservers.contains(windowID) {
				try await Task.sleep(for: .seconds(1))
				var childWindows =
					if let SLSCopyAssociatedWindows,
						let SLSMainConnectionID
					{
						Set(SLSCopyAssociatedWindows(SLSMainConnectionID(), windowID) as? [CGWindowID] ?? [])
					} else {
						Set<CGWindowID>()
					}
				childWindows.remove(windowID)

				let root = try await lookup(windowID: windowID)!
				let overlays = try await windows.filter {
					$0.owningApplication == root.owningApplication && $0.windowLayer > NSWindow.Level.normal.rawValue && $0.frame.intersects(root.frame)
				}.map(\.windowID)

				continuation.yield(Array(childWindows) + overlays)
			}
			continuation.finish()
		}
		return stream
	}

	func stopWatchingForChildren(windowID: CGWindowID) {
		let result = childObservers.remove(windowID)
		assert(result != nil)
	}
}
