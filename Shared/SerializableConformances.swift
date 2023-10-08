//
//  SerializableConformances.swift
//  MacCast
//
//  Created by Saagar Jha on 10/10/23.
//

import CoreMedia
import Foundation

struct SerializableVoid: Serializable {
	func encode() -> Data {
		Data()
	}

	static func decode(_ data: Data) -> Self {
		assert(data.isEmpty)
		return .init()
	}
}

extension Serializable where Self: Codable {
	func encode() throws -> Data {
		try Encoder().encode(self)
	}

	static func decode(_ data: Data) throws -> Self {
		try Decoder().decode(Self.self, from: data)
	}
}

extension Optional: Serializable where Wrapped: Serializable {
	func encode() throws -> Data {
		if let self {
			return try Data([1]) + self.encode()
		} else {
			return Data([0])
		}
	}

	static func decode(_ data: Data) throws -> Self {
		let discriminator = data.first!
		let rest = data.dropFirst()
		switch discriminator {
			case 0:
				return nil
			case 1:
				return try Wrapped.decode(rest)
			default:
				fatalError()
		}
	}
}

extension Data: Serializable {
	func encode() -> Data {
		self
	}

	static func decode(_ data: Data) -> Self {
		data
	}
}

extension CMTime: Serializable {
	func encode() -> Data {
		value.uleb128 + timescale.uleb128
	}

	static func decode(_ data: Data) throws -> Self {
		var data = data
		return try CMTime(value: .init(uleb128: &data), timescale: .init(uleb128: &data))
	}
}

extension CMFormatDescription: Serializable {
	func encode() throws -> Data {
		var extensions = [String: Data]()
		for (key, value) in self.extensions {
			extensions[key as String] = CFPropertyListCreateData(kCFAllocatorDefault, value, .binaryFormat_v1_0, 0, nil).takeRetainedValue() as Data
		}
		let serialized = try Encoder().encode(extensions)
		return mediaSubType.rawValue.uleb128 + dimensions.width.uleb128 + dimensions.height.uleb128 + serialized
	}

	static func decode(_ data: Data) throws -> Self {
		var data = data
		let codecType = try FourCharCode(uleb128: &data)
		let width = try Int32(uleb128: &data)
		let height = try Int32(uleb128: &data)
		let deserialized = try Decoder().decode([String: Data].self, from: data)
		var extensions = [String: CFPropertyList]()
		for (key, value) in deserialized {
			extensions[key] = CFPropertyListCreateWithData(kCFAllocatorDefault, value as CFData, 0, nil, nil).takeRetainedValue()
		}
		var formatDescription: CMFormatDescription?
		let status = CMVideoFormatDescriptionCreate(allocator: kCFAllocatorDefault, codecType: codecType, width: width, height: height, extensions: extensions as CFDictionary, formatDescriptionOut: &formatDescription)
		guard status == noErr else {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
		}
		return formatDescription! as! Self
	}
}

extension CMSampleBuffer: Serializable {
	func encode() throws -> Data {
		try SerializablePack(values: (duration, presentationTimeStamp, decodeTimeStamp, formatDescription!, try dataBuffer!.dataBytes())).encode()
	}

	static func decode(_ data: Data) throws -> Self {
		let (duration, presentationTimeStamp, decodeTimeStamp, formatDescription, data) = try! SerializablePack<CMTime, CMTime, CMTime, CMFormatDescription, Data>.decode(data).values

		var timing = CMSampleTimingInfo(duration: duration, presentationTimeStamp: presentationTimeStamp, decodeTimeStamp: decodeTimeStamp)

		let pointer = UnsafeMutableRawBufferPointer.allocate(byteCount: data.count, alignment: 1)
		data.withUnsafeBytes {
			pointer.copyMemory(from: $0)
		}
		let buffer = try CMBlockBuffer(buffer: pointer) { pointer, _ in
			pointer.deallocate()
		}

		var count = data.count

		var sampleBuffer: CMSampleBuffer?
		let status = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault, dataBuffer: buffer, formatDescription: formatDescription, sampleCount: 1, sampleTimingEntryCount: 1, sampleTimingArray: &timing, sampleSizeEntryCount: 1, sampleSizeArray: &count, sampleBufferOut: &sampleBuffer)
		guard status == noErr else {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
		}
		return sampleBuffer! as! Self
	}
}
