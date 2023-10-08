//
//  Serializable.swift
//  MacCast
//
//  Created by Saagar Jha on 10/9/23.
//

import Cod
import Foundation

protocol Serializable {
	typealias Encoder = CodEncoder
	typealias Decoder = CodDecoder

	func encode() throws -> Data
	static func decode(_ data: Data) throws -> Self
}

struct SerializablePack<each Value: Serializable>: Serializable {
	let values: (repeat each Value)

	struct EncodingContext {
		var values = [Data]()

		var data: Data {
			let sizes = values.map(\.count.uleb128)
			return (sizes + values).reduce(Data(), +)
		}

		mutating func encode(_ value: some Serializable) throws {
			try values.append(value.encode())
		}
	}

	func encode() throws -> Data {
		var context = EncodingContext()
		repeat try context.encode(each values)
		return context.data
	}

	struct DecodingContext {
		var values: [Data]
		var index = 0

		init(data: Data, count: Int) throws {
			var data = data
			var sizes = [Int]()
			for _ in 1...count {
				sizes.append(try Int(uleb128: &data))
			}
			values = []
			var index = data.startIndex
			for size in sizes {
				values.append(data[index..<index + size])
				index += size
			}
		}

		mutating func decode<T: Serializable>(_ type: T.Type) throws -> T {
			defer {
				index += 1
			}
			return try T.decode(values[index])
		}
	}

	struct PackCounter<each T> {
		struct Counter {
			var count = 0

			mutating func count<_T>(_ type: _T.Type) {
				count += 1
			}
		}

		static var count: Int {
			var counter = Counter()
			repeat counter.count((each T).self)
			return counter.count
		}
	}

	static func decode(_ data: Data) throws -> Self {
		var context = try DecodingContext(data: data, count: PackCounter<repeat each Value>.count)
		return self.init(values: (repeat try context.decode((each Value).self)))
	}
}
