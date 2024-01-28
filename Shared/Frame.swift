//
//  Frame.swift
//  Shared
//
//  Created by Saagar Jha on 10/22/23.
//

import Accelerate
import CoreMedia
import CoreVideo
import CryptoKit

struct Frame: Serializable {
	enum Storage {
		case encoded(frame: CMSampleBuffer, mask: vImage.PixelBuffer<vImage.Planar8>)
		case decodedMaskless(image: CVImageBuffer)
		case decoded(image: CVImageBuffer, mask: CVImageBuffer)
	}
	var storage: Storage
	var skipMask: Bool = false

	var mask: vImage.PixelBuffer<vImage.Planar8> {
		guard case let .encoded(_, mask) = storage else {
			preconditionFailure()
		}
		return mask
	}

	var maskHash: SHA256Digest?

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

		// Since we'll be taking a hash of this buffer later, fully initialize
		// it (there may be padding bytes in the rows).
		mask.withUnsafeMutableBufferPointer {
			$0.initialize(repeating: 0)
		}

		source.extractChannel(at: 3 /* BGR[A] */, destination: mask)

		storage = try await .encoded(frame: VideoEncoder.encode(image: frame), mask: mask)
	}

	init(frame: CMSampleBuffer, mask: vImage.PixelBuffer<vImage.Planar8>?) async throws {
		let image = try await VideoDecoder.decode(image: frame)
		guard let mask = mask else {
			storage = .decodedMaskless(image: image)
			return
		}

		maskHash = mask.withUnsafeBufferPointer {
			SHA256.hash(data: $0)
		}

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

		let base = mask.width.uleb128 + mask.height.uleb128 + mask.rowStride.uleb128 + (skipMask ? Data([0]) : Data([1]))

		guard !skipMask else {
			return try await base + frame.encode()
		}

		let data = try mask.withUnsafeBufferPointer {
			try (Data(bytes: $0.baseAddress!, count: $0.count) as NSData).compressed(using: .lz4) as Data
		}

		return try await base + SerializablePack(values: (frame, data)).encode()
	}

	static func decode(_ data: Data) async throws -> Self {
		var data = data
		let width = try Int(uleb128: &data)
		let height = try Int(uleb128: &data)
		let rowStride = try Int(uleb128: &data)

		let hasMask = data.first! != 0
		data = data.dropFirst()

		if hasMask {
			let (frame, compressedData) = try await SerializablePack<CMSampleBuffer, Data>.decode(data).values
			let buffer = try (compressedData as NSData).decompressed(using: .lz4)
			defer {
				withExtendedLifetime(buffer) {}
			}

			let mask = vImage.PixelBuffer<vImage.Planar8>(data: UnsafeMutableRawPointer(mutating: buffer.bytes), width: width, height: height, byteCountPerRow: rowStride)
			return try await Self.init(frame: frame, mask: mask)
		} else {
			let frame = try await CMSampleBuffer.decode(data)
			return try await Self.init(frame: frame, mask: nil)
		}
	}

	mutating func augmentWithMask(_ oldMask: CVImageBuffer) {
		if case let .decodedMaskless(image) = storage {
			storage = .decoded(image: image, mask: oldMask)
		}
	}
}
