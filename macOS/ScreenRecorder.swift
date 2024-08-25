//
//  ScreenRecorder.swift
//  macOS
//
//  Created by Saagar Jha on 10/21/23.
//

import AVFoundation
import ScreenCaptureKit

actor ScreenRecorder {
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
		
		let frames: AsyncStream<CMSampleBuffer>
		let continuation: AsyncStream<CMSampleBuffer>.Continuation

		let output: Output
		let stream: SCStream

		init(window: SCWindow) async throws {
			(frames, continuation) = AsyncStream.makeStream(of: CMSampleBuffer.self, bufferingPolicy: .bufferingNewest(1))
			
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
}
