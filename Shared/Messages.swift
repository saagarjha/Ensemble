//
//  Messages.swift
//  Shared
//
//  Created by Saagar Jha on 10/9/23.
//

import Foundation

enum Messages: UInt8, CaseIterable {
	static let version = Bundle.main.version
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
	case scrollBegan
	case scrollChanged
	case scrollEnded
	case dragBegan
	case dragChanged
	case dragEnded
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
