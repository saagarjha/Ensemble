//
//  WindowManager.swift
//  macOS
//
//  Created by Saagar Jha on 1/29/24.
//

import ApplicationServices
import ScreenCaptureKit

actor WindowManager {
	var applications = [pid_t: Application]()
	var windows = [CGWindowID: Window]()

	class Application {
		let application: SCRunningApplication
		var windows: [Window]

		var windowUpdates: AsyncStream<Void> {
			if Permission.helper.supported && Permission.helper.enabled {
				let stream = AXObserver.observe([kAXCreatedNotification, kAXMenuOpenedNotification, kAXUIElementDestroyedNotification], for: AXUIElementCreateApplication(application.processID))
				var iterator = stream.makeAsyncIterator()

				return AsyncStream {
					_ = await iterator.next()
				}
			} else {
				return AsyncStream {
					try? await Task.sleep(for: .seconds(1))
				}
			}
		}

		init(application: SCRunningApplication) {
			self.application = application
			windows = []
		}

		func childWindows(of window: Window) -> [CGWindowID] {
			var childWindows =
				if let SLSCopyAssociatedWindows,
					let SLSMainConnectionID
				{
					Set(SLSCopyAssociatedWindows(SLSMainConnectionID(), window.window.windowID) as? [CGWindowID] ?? [])
				} else {
					Set<CGWindowID>()
				}
			childWindows.remove(window.window.windowID)

			let overlays = windows.filter {
				$0.window.windowLayer > NSWindow.Level.normal.rawValue && $0.window.frame.intersects(window.window.frame)
			}.map(\.window.windowID)

			return Array(childWindows) + overlays
		}

		static func sameApplication(lhs: SCRunningApplication, rhs: SCRunningApplication) -> Bool {
			lhs.processID == rhs.processID && lhs.bundleIdentifier == rhs.bundleIdentifier && lhs.applicationName == rhs.applicationName
		}
	}

	struct Window {
		weak var application: Application!
		let window: SCWindow
	}

	func updateWindows() async throws {
		var newApplications = [pid_t: Application]()
		for application in applications.values {
			application.windows.removeAll()
		}
		windows.removeAll()

		func lookup(application: SCRunningApplication) -> Application {
			if let _application = newApplications[application.processID] {
				assert(Application.sameApplication(lhs: application, rhs: _application.application))
				return _application
			}

			if let _application = applications[application.processID],
				Application.sameApplication(lhs: application, rhs: _application.application)
			{
				newApplications[application.processID] = _application
				return _application
			}

			let _application = Application(application: application)
			newApplications[application.processID] = _application
			return _application
		}

		for window in try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false).windows where window.owningApplication != nil {
			let _application = lookup(application: window.owningApplication!)
			let _window = Window(application: _application, window: window)
			_application.windows.append(_window)
			windows[window.windowID] = _window
		}

		applications = newApplications
	}

	func childrenOfWindow(idenitifiedBy windowID: CGWindowID) -> AsyncThrowingStream<[CGWindowID], Error> {
		let window = windows[windowID]!
		let application = window.application!
		var iterator = application.windowUpdates.makeAsyncIterator()
		return AsyncThrowingStream {
			await iterator.next()
			try await self.updateWindows()
			return application.childWindows(of: window)
		}
	}

	func lookupWindow(byID id: CGWindowID) async throws -> SCWindow? {
		guard let window = windows[id]?.window else {
			try await updateWindows()
			return windows[id]?.window
		}
		return window
	}

	var allWindows: [SCWindow] {
		get async throws {
			try await updateWindows()
			return windows.values.map(\.window)
		}
	}
}

extension AXObserver {
	static func observe(_ notifications: [String], for element: AXUIElement) -> AsyncStream<(AXUIElement, String)> {
		AsyncStream<(AXUIElement, String)> { continuation in
			var pid: pid_t = 0
			AXUIElementGetPid(element, &pid)
			var observer: AXObserver!

			AXObserverCreate(
				pid,
				{ _, element, notification, refcon in
					let continuation = Unmanaged<AnyObject>.fromOpaque(refcon!).takeUnretainedValue() as! AsyncStream<(AXUIElement, String)>.Continuation
					continuation.yield((element, notification as String))
				}, &observer)
			for notification in notifications {
				AXObserverAddNotification(observer, element, notification as CFString, Unmanaged.passRetained(continuation as AnyObject).toOpaque())
			}
			CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)

			// Retain the observer until the stream is finished
			let _observer = observer
			continuation.onTermination = { _ in
				withExtendedLifetime(_observer) {}
			}
		}
	}
}
