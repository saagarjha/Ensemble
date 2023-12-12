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

	init() {
		coordinator = .init(view: view)
	}

	class Coordinator {
		let view: UIView
		let (hoverStream, hoverContinuation) = AsyncStream.makeStream(of: CGPoint.self)
		let (panStream, panContinuation) = AsyncStream.makeStream(of: CGPoint.self)

		init(view: UIView) {
			self.view = view
		}

		@objc
		func hover(_ sender: UIHoverGestureRecognizer) {
			hoverContinuation.yield(sender.location(in: view))
		}

		@objc
		func pan(_ sender: UIPanGestureRecognizer) {
			panContinuation.yield(sender.translation(in: view))
			sender.setTranslation(.zero, in: view)
		}
	}

	func makeUIView(context: Context) -> some UIView {
		return view
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {
	}

	func makeCoordinator() -> Coordinator {
		let hoverGestureRecognizer = UIHoverGestureRecognizer(target: coordinator, action: #selector(Coordinator.hover(_:)))
		view.addGestureRecognizer(hoverGestureRecognizer)

		let panGestureRecognizer = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.pan(_:)))
		panGestureRecognizer.allowedScrollTypesMask = .all
		view.addGestureRecognizer(panGestureRecognizer)
		return coordinator
	}
}

#Preview {
	EventView()
}
