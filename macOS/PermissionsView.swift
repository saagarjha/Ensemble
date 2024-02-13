//
//  PermissionsView.swift
//  macOS
//
//  Created by Saagar Jha on 2/6/24.
//

import SwiftUI

struct PermissionsView: View {
	@Binding
	var askForPermissions: Bool
	@State
	var showInstallHelper = false
	// Updates the view
	@State
	var _updatePermissions = false

	@Preference
	var suppressPermissionsView: Bool

	var body: some View {
		VStack(spacing: 12) {
			let _ = _updatePermissions

			HStack(spacing: 20) {
				Image(nsImage: NSImage(named: NSImage.applicationIconName)!)
					.renderingMode(.original)
					.resizable()
					.scaledToFit()
					.fixedSize()
					.scaleEffect(.init(width: 0.9, height: 0.9))

				VStack(alignment: .leading, spacing: 8) {
					Text("Welcome to Ensemble.")
						.font(.system(.title))
					Text("\(Bundle.main.name) works best when it can interact with certain sensitive features of your computer. Without permission to access them, some parts of the app may not function correctly.")
						.fixedSize(horizontal: false, vertical: true)
					Spacer()
						.frame(height: 0)
					Toggle("Do not show this again", isOn: $suppressPermissionsView)
						.controlSize(.small)
				}
				.frame(maxWidth: 400)
			}
			Divider()
			HStack(spacing: 0) {
				// TODO: Figure out if I can use alignment guides or something
				Spacer()
					.frame(width: 100)
				Form {
					ForEach(Permission.allCases) { permission in
						LabeledContent(permission.name) {
							VStack(alignment: .leading) {
								Button(action: {
									guard permission != .helper else {
										showInstallHelper = true
										return
									}
									permission.request()
								}) {
									HStack(spacing: 4) {
										if !permission.supported {
											Image(systemName: "exclamationmark.circle")
												.symbolRenderingMode(.multicolor)
										} else if permission.enabled {
											Image(systemName: "checkmark.circle")
												.symbolRenderingMode(.multicolor)
										}
										Text(permission.prompt)
									}
									.frame(width: 128)
								}
								.disabled(permission.enabled || !permission.supported)
								Text(permission.reason)
									.font(.caption)
									.foregroundStyle(.secondary)
							}
							.padding(4)
						}
					}
				}
				.frame(width: 384)
				Spacer()
			}
			.frame(maxWidth: .infinity)
			Divider()
			HStack {
				Spacer()
				Button(action: {
					askForPermissions = false
				}) {
					Text("Done")
						.frame(width: 48)
				}
				.keyboardShortcut(.defaultAction)
			}
		}
		.padding(20)
		.fixedSize(horizontal: true, vertical: true)
		.task {
			while true {
				try? await Task.sleep(for: .seconds(1))
				_updatePermissions.toggle()
				if askForPermissions {
					askForPermissions = !Permission.allCases.allSatisfy(\.enabled)
				}
			}
		}
		.overlay {
			PreventsApplicationTerminationWhenModalView()
		}
		.alert(
			"Install \(Bundle.main.name) Helper", isPresented: $showInstallHelper,
			actions: {
				Button("Start") {
					Permission.helper.request()
				}
				.keyboardShortcut(.defaultAction)
				Button("Cancel") {}
					.keyboardShortcut(.cancelAction)
			}
		) {
			Text(
				"""
				The \(Bundle.main.name) Helper builds on the Accessibility permission to provide the app authority to all user interface elements on your Mac. This allows it to direct events at specific apps, interact with menus, and be notified of changes in window layout.

				This access powers some of the most advanced features of \(Bundle.main.name), but must be installed manually. To authorize access, please copy \(Permission.helperScriptName) to this application's scripts directory.
				""")
		}
	}
}

struct PreventsApplicationTerminationWhenModalView: NSViewRepresentable {
	class _View: NSView {
		override func viewDidMoveToWindow() {
			window?.preventsApplicationTerminationWhenModal = false
		}

		override func hitTest(_ point: NSPoint) -> NSView? {
			nil
		}
	}

	func makeNSView(context: Context) -> some NSView {
		_View()
	}

	func updateNSView(_ nsView: NSViewType, context: Context) {
	}
}

#Preview {
	PermissionsView(askForPermissions: .constant(true), suppressPermissionsView: .init(previewing: false))
}
