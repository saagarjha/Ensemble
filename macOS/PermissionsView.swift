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
			HStack {
				// TODO: Figure out if I can use alignment guides or something
				Spacer()
					.frame(width: 100)
				Form {
					ForEach(Permission.allCases) { permission in
						LabeledContent(permission.name) {
							VStack(alignment: .leading) {
								Button(action: {
									permission.request()
								}) {
									HStack(spacing: 4) {
										if permission.enabled {
											Image(systemName: "checkmark.circle")
												.symbolRenderingMode(.multicolor)
											Text("Enabled!")
										} else {
											Text("Request…")
										}
									}
									.frame(width: 100)
								}
								.disabled(permission.enabled)
								Text(permission.reason)
									.font(.caption)
									.foregroundStyle(.secondary)
									.frame(maxWidth: 300)
									.fixedSize(horizontal: false, vertical: true)
							}
							.padding(4)
						}
					}
				}
			}
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
		// FB13593200
		.padding(.bottom, 24)
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
