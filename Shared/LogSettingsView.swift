//
//  LogSettingsView.swift
//  Shared
//
//  Created by Saagar Jha on 5/28/24.
//

import SwiftUI

struct LogSettingsView: View {
	@Preference(\.persistedHistoricalLogs)
	var persistedHistoricalLogs
	@Preference(\.transientLogSize)
	var transientLogSize
	@Preference(\.persistentLogSize)
	var persistentLogSize

	@Binding
	var showSettings: Bool

	@FocusState
	var persistedHistoricalLogsFocused
	@FocusState
	var transientLogSizeFocused
	@FocusState
	var persistentLogSizeFocused

	var body: some View {
		func wrapInNavigationStack(_ view: some View) -> some View {
			#if os(visionOS)
				return NavigationStack {
					view
				}
			#else
				return view
			#endif
		}

		return wrapInNavigationStack(
			VStack {
				Form {
					LabeledContent("Save:") {
						HStack {
							TextField("", value: $persistedHistoricalLogs, format: .number)
								#if os(visionOS)
									.multilineTextAlignment(.trailing)
									.focused($persistedHistoricalLogsFocused)
								#endif
							Text("logs")
								.onTapGesture {
									persistedHistoricalLogsFocused = true
								}
						}
					}
					LabeledContent("Transient Buffer Size:") {
						HStack {
							TextField("", value: $transientLogSize, format: .number)
								#if os(visionOS)
									.multilineTextAlignment(.trailing)
									.focused($transientLogSizeFocused)
								#endif
							Text("bytes")
								.onTapGesture {
									transientLogSizeFocused = true
								}
						}
					}
					LabeledContent("Persistent Buffer Size:") {
						HStack {
							TextField("", value: $persistentLogSize, format: .number)
								#if os(visionOS)
									.multilineTextAlignment(.trailing)
									.focused($persistentLogSizeFocused)
								#endif
							Text("bytes")
								.onTapGesture {
									persistentLogSizeFocused = true
								}
						}
					}
				}
				#if os(visionOS)
					.navigationTitle("Log Settings")
					.toolbar {
						Button("Done") {
							showSettings = false
						}
					}
				#endif

				#if os(macOS)
					.padding()
				#endif

				#if os(macOS)
					HStack {
						Spacer()

						Button(action: {
							showSettings = false
						}) {
							Text("OK")
								#if os(macOS)
									.frame(width: 48)
								#endif
						}
						.keyboardShortcut(.defaultAction)
					}
				#endif
			}
		)
		#if os(macOS)
			.padding()
		#endif
	}
}

#Preview {
	LogSettingsView(showSettings: .constant(true))
}
