//
//  Frame.swift
//  MacCast
//
//  Created by Saagar Jha on 10/22/23.
//

import Accelerate
import CoreMedia
import CoreVideo

struct Frame: Serializable {
	enum Storage {
		case encoded(frame: CMSampleBuffer, mask: vImage.PixelBuffer<vImage.Planar8>)
		case decoded(image: CVImageBuffer, mask: CVImageBuffer)
	}
	var storage: Storage

	var frame: (CVImageBuffer, CVImageBuffer) {
		guard case let .decoded(image, mask) = storage else {
			preconditionFailure()
		}
		return (image, mask)
	}

	init(frame: CMSampleBuffer) async throws {
		let image = frame.imageBuffer!
		precondition(CVPixelBufferGetPixelFormatType(image) == kCVPixelFormatType_32BGRA)

		CVPixelBufferLockBaseAddress(image, .readOnly)
		defer {
			CVPixelBufferUnlockBaseAddress(image, .readOnly)
		}
		let source = vImage.PixelBuffer<vImage.Interleaved8x4>(data: CVPixelBufferGetBaseAddress(image)!, width: CVPixelBufferGetWidth(image), height: CVPixelBufferGetHeight(image), byteCountPerRow: CVPixelBufferGetBytesPerRow(image))

		let mask = vImage.PixelBuffer<vImage.Planar8>(size: .init(cvPixelBuffer: image))

		source.extractChannel(at: 3 /* BGR[A] */, destination: mask)

		storage = try await .encoded(frame: VideoEncoder.encode(image: frame), mask: mask)
	}

	init(frame: CMSampleBuffer, mask: vImage.PixelBuffer<vImage.Planar8>) async throws {
		let image = try await VideoDecoder.decode(image: frame)
		assert(CVPixelBufferGetWidth(image) == mask.width)
		assert(CVPixelBufferGetHeight(image) == mask.height)

		var maskImage: CVImageBuffer!

		CVPixelBufferCreate(kCFAllocatorDefault, CVPixelBufferGetWidth(image), CVPixelBufferGetHeight(image), kCVPixelFormatType_32BGRA, nil, &maskImage)

		CVPixelBufferLockBaseAddress(maskImage, [])
		defer {
			CVPixelBufferUnlockBaseAddress(maskImage, [])
		}

		let buffer = vImage.PixelBuffer<vImage.Interleaved8x4>(data: CVPixelBufferGetBaseAddress(maskImage)!, width: mask.width, height: mask.height, byteCountPerRow: CVPixelBufferGetBytesPerRow(maskImage))
		// In theory we only care about the last channel, which contains alpha.
		// However, it doesn't hurt to initialize the others too.
		buffer.overwriteChannels([0, 1, 2, 3], withPlanarBuffer: mask, destination: buffer)

		storage = .decoded(image: image, mask: maskImage)
	}

	func encode() async throws -> Data {
		guard case let .encoded(frame, mask) = storage else {
			preconditionFailure()
		}

		let data = try mask.withUnsafeBufferPointer {
			try (Data(bytes: $0.baseAddress!, count: $0.count) as NSData).compressed(using: .lz4) as Data
		}

		return try await mask.width.uleb128 + mask.height.uleb128 + mask.rowStride.uleb128 + SerializablePack(values: (frame, data)).encode()
	}

	static func decode(_ data: Data) async throws -> Self {
		var data = data
		let width = try Int(uleb128: &data)
		let height = try Int(uleb128: &data)
		let rowStride = try Int(uleb128: &data)
		let (frame, compressedData) = try await SerializablePack<CMSampleBuffer, Data>.decode(data).values
		let buffer = try (compressedData as NSData).decompressed(using: .lz4)
		defer {
			withExtendedLifetime(buffer) {}
		}

		let mask = vImage.PixelBuffer<vImage.Planar8>(data: UnsafeMutableRawPointer(mutating: buffer.bytes), width: width, height: height, byteCountPerRow: rowStride)
		return try await Self.init(frame: frame, mask: mask)

	}
}
