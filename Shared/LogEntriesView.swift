//
//  LogEntriesView.swift
//  Shared
//
//  Created by Saagar Jha on 5/27/24.
//

import Chronicle
import SwiftUI

struct LogEntriesView: View {
	struct IdentifiableEntry: Identifiable {
		let id: Int
		let entry: Entry
	}

	let log: URL

	@State
	var entries: Result<[Entry], Error>?
	@State
	var selection: Int?

	enum Chronicle: String, CaseIterable, Identifiable {
		case transient
		case persistent

		var id: Self {
			self
		}

		var path: String {
			switch self {
				case .transient:
					Log.transientPath
				case .persistent:
					Log.persistentPath
			}
		}
	}

	@State
	var chronicle = Chronicle.transient

	@State
	var filter = ""

	@State
	var timestampWidth: CGFloat?

	var body: some View {
		Group {
			switch entries {
				case .success(let entries):
					Table(
						entries.enumerated().map(IdentifiableEntry.init).filter {
							filter.isEmpty || $0.entry.description.localizedStandardContains(filter)
						}, selection: $selection
					) {
						TableColumn("Timestamp") {
							Text($0.entry.timestamp.formatted())
								.overlay {
									GeometryReader { geometry in
										Color.clear.onChange(of: geometry.size.width, initial: true) {
											// On visionOS, there is some extra
											// padding I don't know how to get
											// rid of or measure.
											let padding: CGFloat
											#if os(visionOS)
												padding = 40
											#else
												padding = 0
											#endif
											timestampWidth = max(timestampWidth ?? 0, geometry.size.width + padding)
										}
									}
								}
						}
						.width(min: timestampWidth, max: timestampWidth)
						TableColumn("Message") {
							Text($0.entry.fields.map(\.description).joined())
						}
					}
					// This is exceptionally awful. However, it is quite
					// straightforward: if we use the timestamp width as the
					// identity for this table, then a redraw is triggered when
					// the width changes (which is the effect we want).
					.id(timestampWidth)
					.font(.system(.body).monospaced())
				case .failure(let error):
					ContentUnavailableView("\(log.lastPathComponent) was not readable.", systemImage: "doc.questionmark.fill", description: Text("\(error)"))
					Text("")
				case nil:
					ProgressView {
						Text("Loading entries…")
					}
					.task {
						entries = Result {
							try Array(Epilog(url: log.appendingPathComponent(chronicle.path)).entries)
						}
					}
			}
		}
		.toolbar {
			Picker("Log", selection: $chronicle) {
				ForEach(Chronicle.allCases) {
					Text($0.rawValue.capitalized)
						.tag($0)
				}
			}
			#if os(visionOS)
				.pickerStyle(.segmented)
			#endif
			.onChange(of: chronicle) {
				self.entries = nil
			}
		}
		.searchable(text: $filter)
		.navigationTitle(log.lastPathComponent)
		.navigationDocument(log)
	}
}
