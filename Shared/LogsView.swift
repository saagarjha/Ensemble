//
//  LogsView.swift
//  Shared
//
//  Created by Saagar Jha on 4/17/24.
//

import Chronicle
import SwiftUI

struct LogsView: View {
	@State
	var selection: URL?

	@State
	var deletionGeneration = 0

	@State
	var showSettings = false

	var body: some View {
		NavigationSplitView(
			sidebar: {
				List(
					Log.logs.sorted {
						$0.time < $1.time
					}, selection: $selection
				) { log in
					VStack(alignment: .leading) {
						Text(log.url.lastPathComponent)
						Text("\(log.size, format: .byteCount(style: .memory))")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					.contextMenu {
						ShareLink(item: log, preview: SharePreview(log.url.lastPathComponent, icon: Image(systemName: "doc.zipper"))) {
							Text("Share…")
						}
						#if os(macOS)
							Button("Show in Finder") {
								NSWorkspace.shared.selectFile(log.url.path, inFileViewerRootedAtPath: log.url.deletingLastPathComponent().path)
							}
						#endif
					}
					.swipeActions(allowsFullSwipe: true) {
						Button(
							role: .destructive,
							action: {
								if selection == log.id {
									selection = nil
								}
								log.delete()
								deletionGeneration += 1
							},
							label: {
								Label("Delete", systemImage: "trash")
							})
						// FB13811218
						ShareLink(item: log, preview: SharePreview(log.url.lastPathComponent, icon: Image(systemName: "doc.zipper"))) {
							Image(systemName: "square.and.arrow.up")
						}
					}
				}
				.navigationTitle("Logs")
				.navigationSplitViewColumnWidth(min: 200, ideal: 300)
				.toolbar {
					Spacer()
					Button(
						action: {
							showSettings = true
						},
						label: {
							Image(systemName: "gearshape")
						})
				}
				.sheet(isPresented: $showSettings) {
					LogSettingsView(showSettings: $showSettings)
				}
			},
			detail: {
				if let selection {
					LogEntriesView(log: selection)
						.id(selection)
						#if os(macOS)
							.toolbar {
								let log = Log.logs.first {
									$0.url == selection
								}!
								ShareLink(item: log, preview: SharePreview(selection.lastPathComponent, icon: Image(systemName: "doc.zipper"))) {
									Label("Share", systemImage: "square.and.arrow.up")
								}
							}
						#endif
				} else {
					Text("No log selected")
				}
			}
		)
		.id(deletionGeneration)
	}
}

#Preview {
	LogsView()
}
