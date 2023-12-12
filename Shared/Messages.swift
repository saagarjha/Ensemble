//
//  Messages.swift
//  MacCast
//
//  Created by Saagar Jha on 10/9/23.
//

enum Messages: UInt8, CaseIterable {
	static let version = 1
	case visionOSHandshake
	case macOSHandshake
	case windows
	case windowPreview
	case startCasting
	case stopCasting
	case windowFrame
	case windowMask
	case startWatchingForChildWindows
	case stopWatchingForChildWindows
	case childWindows
	case mouseMoved
	case clicked
	case scrolled
	case typed
}

protocol Message {
	static var id: Messages { get }
	associatedtype Request: Serializable
	associatedtype Reply: Serializable
}

extension Message {
	static func send(_ parameters: Request, through connection: Multiplexer) async throws -> Reply {
		try await .decode(connection.sendWithReply(message: Self.id, data: parameters.encode()))
	}
}
