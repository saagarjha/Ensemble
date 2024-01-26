//
//  EventView.swift
//  visionOS
//
//  Created by Saagar Jha on 12/12/23.
//

import SwiftUI

class KeyView: UIView {
	let (keyStream, keyContinuation) = AsyncStream.makeStream(of: (Key, Bool).self)

	override var canBecomeFirstResponder: Bool {
		true
	}

	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		for press in presses {
			if let _key = press.key,
				let key = Key(visionOSCode: _key.keyCode)
			{
				keyContinuation.yield((key, true))
			}
		}
	}

	override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		for press in presses {
			if let _key = press.key,
				let key = Key(visionOSCode: _key.keyCode)
			{
				keyContinuation.yield((key, false))
			}
		}
	}
}

struct EventView: UIViewRepresentable {
	let view = KeyView()
	let coordinator: Coordinator

	enum ScrollEvent {
		case began
		case changed(CGPoint)
		case ended
	}

	enum DragEvent {
		case began(CGPoint)
		case changed(CGPoint)
		case ended(CGPoint)
	}

	init() {
		coordinator = .init(view: view)
	}

	class Coordinator {
		let view: UIView
		let (scrollStream, scrollContinuation) = AsyncStream.makeStream(of: ScrollEvent.self)
		let (dragStream, dragContinuation) = AsyncStream.makeStream(of: DragEvent.self)

		init(view: UIView) {
			self.view = view
		}

		@objc
		func scroll(_ sender: UIPanGestureRecognizer) {
			switch sender.state {
				case .began:
					scrollContinuation.yield(.began)
				case .changed:
					scrollContinuation.yield(.changed(sender.translation(in: view)))
					sender.setTranslation(.zero, in: view)
				case .ended:
					scrollContinuation.yield(.ended)
				default:
					return
			}
		}

		@objc
		func pan(_ sender: UIPanGestureRecognizer) {
			var position = sender.location(in: view)
			position.x /= view.frame.width
			position.y /= view.frame.height
			switch sender.state {
				case .began:
					dragContinuation.yield(.began(position))
				case .changed:
					dragContinuation.yield(.changed(position))
				case .ended:
					dragContinuation.yield(.ended(position))
				default:
					return
			}
		}
	}

	func makeUIView(context: Context) -> some UIView {
		return view
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {
	}

	func makeCoordinator() -> Coordinator {
		let scrollGestureRecognizer = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.scroll(_:)))
		scrollGestureRecognizer.allowedScrollTypesMask = .all
		scrollGestureRecognizer.allowedTouchTypes = []
		view.addGestureRecognizer(scrollGestureRecognizer)

		let dragGestureRecognizer = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.pan(_:)))
		view.addGestureRecognizer(dragGestureRecognizer)
		return coordinator
	}
}

#Preview {
	EventView()
}
