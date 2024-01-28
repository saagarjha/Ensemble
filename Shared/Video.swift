//
//  Video.swift
//  Shared
//
//  Created by Saagar Jha on 10/10/23.
//

import VideoToolbox

struct VideoEncoder {
	class State {
		var session: VTCompressionSession!
		let (stream, continuation) = AsyncThrowingStream.makeStream(of: CMSampleBuffer.self, bufferingPolicy: .bufferingNewest(1))

		func initialize(imageBuffer: CVImageBuffer) throws {
			guard session == nil else {
				return
			}

			let status = VTCompressionSessionCreate(
				allocator: kCFAllocatorDefault,
				width: Int32(CVPixelBufferGetWidth(imageBuffer)),
				height: Int32(CVPixelBufferGetHeight(imageBuffer)),
				codecType: kCMVideoCodecType_JPEG,
				encoderSpecification: nil,
				imageBufferAttributes: [
					kCVPixelBufferPixelFormatTypeKey: CVPixelBufferGetPixelFormatType(imageBuffer) as CFNumber
				] as CFDictionary,
				compressedDataAllocator: nil,
				outputCallback: nil,
				refcon: nil,
				compressionSessionOut: &session)
			guard status == noErr else {
				throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
			}

			assert(VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue) == noErr)
		}

		func encode(_ frame: CMSampleBuffer) {
			VTCompressionSessionEncodeFrame(self.session, imageBuffer: frame.imageBuffer!, presentationTimeStamp: frame.presentationTimeStamp, duration: frame.duration, frameProperties: nil, infoFlagsOut: nil) { status, _, buffer in
				guard status == noErr else {
					self.continuation.finish(throwing: NSError(domain: NSOSStatusErrorDomain, code: Int(status)))
					return
				}

				if let buffer {
					self.continuation.yield(buffer)
				}
			}
		}

		func synchronize(to time: CMTime) {
			VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: time)
		}
	}
	let state = State()

	var frames: AsyncThrowingStream<CMSampleBuffer, Error> {
		state.stream
	}

	func encode(_ frame: CMSampleBuffer) throws {
		try state.initialize(imageBuffer: frame.imageBuffer!)
		state.encode(frame)
	}

	static func encode(image: CMSampleBuffer) async throws -> CMSampleBuffer {
		let encoder = Self()
		try encoder.encode(image)
		encoder.state.synchronize(to: image.presentationTimeStamp)
		return try await encoder.frames.first { _ in true }!
	}
}

struct VideoDecoder {
	class State {
		var session: VTDecompressionSession!
		let (stream, continuation) = AsyncThrowingStream.makeStream(of: CVImageBuffer.self, bufferingPolicy: .bufferingNewest(1))
		var latest = CMTime.zero

		func initialize(sampleBuffer: CMSampleBuffer) throws {
			guard session == nil else {
				return
			}

			let status = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault, formatDescription: sampleBuffer.formatDescription!, decoderSpecification: nil, imageBufferAttributes: nil, decompressionSessionOut: &session)
			guard status == noErr else {
				throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
			}
		}

		func decode(_ frame: CMSampleBuffer) {
			VTDecompressionSessionDecodeFrame(session, sampleBuffer: frame, flags: [._EnableTemporalProcessing, ._1xRealTimePlayback, ._EnableAsynchronousDecompression], infoFlagsOut: nil) { status, _, buffer, timestamp, time in
				guard status == noErr else {
					self.continuation.finish(throwing: NSError(domain: NSOSStatusErrorDomain, code: Int(status)))
					return
				}

				if timestamp > self.latest {
					self.latest = timestamp
					self.continuation.yield(buffer!)
				}
			}
		}

		func synchronize() {
			VTDecompressionSessionWaitForAsynchronousFrames(session)
		}
	}
	let state = State()

	var frames: AsyncThrowingStream<CVImageBuffer, Error> {
		state.stream
	}

	func decode(_ frame: CMSampleBuffer) throws {
		try state.initialize(sampleBuffer: frame)
		state.decode(frame)
	}

	static func decode(image: CMSampleBuffer) async throws -> CVImageBuffer {
		let decoder = Self()
		try decoder.decode(image)
		decoder.state.synchronize()
		return try await decoder.frames.first { _ in true }!
	}
}
