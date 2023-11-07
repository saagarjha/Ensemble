//
//  Multiplexer.swift
//  MacCast
//
//  Created by Saagar Jha on 10/9/23.
//

import AppleConnect
import Foundation

struct Multiplexer {
	let connection: Connection
	let localInterface: LocalInterface

	actor Replies {
		var token: Int = 1
		var continuations = [Int: CheckedContinuation<Data, Error>]()

		func enqueue(_ continuation: CheckedContinuation<Data, Error>) -> Int {
			defer {
				token += 1
			}
			continuations[token] = continuation
			return token
		}

		func failAll(with error: Error) {
			for continuation in continuations.values {
				continuation.resume(throwing: error)
			}
			continuations.removeAll()
		}

		func yield(_ data: Data, forToken token: Int) {
			let continuation = continuations.removeValue(forKey: token)!
			continuation.resume(returning: data)
		}
	}
	let replies = Replies()

	init(connection: Connection, localInterface: LocalInterface) {
		self.connection = connection
		self.localInterface = localInterface
		serviceReplies()
	}

	func serviceReplies() {
		Task {
			do {
				for try await data in connection.data {
					Task {
						let message = Messages(rawValue: data.first!)!
						var data = data.dropFirst()
						let token = try Int(uleb128: &data)
						if let data = try await localInterface.handle(message: message, data: data) {
							try await send(message: message, data: data, token: token)
						} else {
							await replies.yield(data, forToken: token)
						}
					}
				}
			} catch {
				await replies.failAll(with: error)
			}
		}
	}

	func send(message: Messages, data: Data) async throws {
		try await send(message: message, data: data, token: 0)
	}

	func sendWithReply(message: Messages, data: Data) async throws -> Data {
		try await withCheckedThrowingContinuation { continuation in
			Task {
				let token = await replies.enqueue(continuation)
				do {
					try await send(message: message, data: data, token: token)
				} catch {
					continuation.resume(throwing: error)
				}
			}
		}
	}

	func send(message: Messages, data: Data, token: Int) async throws {
		try! await connection.send(data: Data([message.rawValue]) + token.uleb128 + data)
	}
}

protocol LocalInterface {
	func handle(message: Messages, data: Data) async throws -> Data?
}
