//
//  EventDispatcher.swift
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

	var lastClick = ContinuousClock.Instant.now
	var clickCount: Int64 = 0

	func injectClick(at location: NSPoint) {
		defer {
			lastClick = .now
		}
		clickCount = ContinuousClock.Instant.now - lastClick < .seconds(NSEvent.doubleClickInterval) ? clickCount + 1 : 1

		for direction in [.leftMouseDown, .leftMouseUp] as [CGEventType] {
			let event = CGEvent(mouseEventSource: nil, mouseType: direction, mouseCursorPosition: location, mouseButton: .left)!
			event.setIntegerValueField(.mouseEventClickState, value: clickCount)
			event.post(tap: .cghidEventTap)
		}
	}

	func injectScrollBegan() {
		let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: 0, wheel2: 0, wheel3: 0)!
		event.setIntegerValueField(.scrollWheelEventScrollPhase, value: Int64(CGGesturePhase.began.rawValue))
		event.post(tap: .cghidEventTap)

	}

	func injectScrollChanged(translationX: CGFloat, translationY: CGFloat) {
		let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: Int32(translationY), wheel2: Int32(translationX), wheel3: 0)!
		event.setIntegerValueField(.scrollWheelEventScrollCount, value: 1)
		event.setIntegerValueField(.scrollWheelEventScrollPhase, value: Int64(CGGesturePhase.changed.rawValue))
		event.post(tap: .cghidEventTap)
	}

	func injectScrollEnded() {
		let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: 0, wheel2: 0, wheel3: 0)!
		event.setIntegerValueField(.scrollWheelEventScrollPhase, value: Int64(CGGesturePhase.ended.rawValue))
		event.post(tap: .cghidEventTap)
	}

	func injectDragBegan(at location: NSPoint) {
		let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: location, mouseButton: .left)!
		event.post(tap: .cghidEventTap)
	}

	func injectDragChanged(to location: NSPoint) {
		let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: location, mouseButton: .left)!
		event.post(tap: .cghidEventTap)
	}

	func injectDragEnded(at location: NSPoint) {
		let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: location, mouseButton: .left)!
		event.post(tap: .cghidEventTap)
	}

	func injectKey(key: Key, down: Bool) {
		// FB13590408
		if let CGPostKeyboardEvent {
			_ = CGPostKeyboardEvent(0, CGKeyCode(key.macOSCode), down ? 1 : 0)
		} else {
			let event = CGEvent(keyboardEventSource: .init(stateID: .hidSystemState), virtualKey: CGKeyCode(key.macOSCode), keyDown: down)!
			event.post(tap: .cghidEventTap)
		}
	}
}

// This is marked as deprecated and unavailable in Swift. Rude.
let CGPostKeyboardEvent = unsafeBitCast(dlsym(dlopen(nil, RTLD_LAZY), "CGPostKeyboardEvent"), to: (@convention(c) (CGCharCode, CGKeyCode, boolean_t) -> CGError)?.self)
