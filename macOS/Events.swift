//
//  Events.swift
//  macOS
//
//  Created by Saagar Jha on 12/12/23.
//

import AppKit

actor EventDispatcher {
	func injectMouseMoved(to location: NSPoint) {
		let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: location, mouseButton: .center)!
		event.post(tap: .cghidEventTap)
	}

	func injectClick(at location: NSPoint) {
		let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: location, mouseButton: .left)!
		let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: location, mouseButton: .left)!
		down.post(tap: .cghidEventTap)
		up.post(tap: .cghidEventTap)
	}

	func injectScroll(translationX: CGFloat, translationY: CGFloat) {
		let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: Int32(translationY), wheel2: Int32(translationX), wheel3: 0)!
		event.post(tap: .cghidEventTap)
	}

	func injectKey(key: Key, down: Bool) {
		let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key.macOSCode), keyDown: down)!
		event.post(tap: .cghidEventTap)
	}
}
