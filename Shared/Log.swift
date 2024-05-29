//
//  Log.swift
//  Shared
//
//  Created by Saagar Jha on 4/17/24.
//

import AppleArchive
import Chronicle
import Foundation
import SwiftUI
import System

struct Log: Identifiable, Hashable, Transferable {
	static let location = {
		let location = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("Logs")
		try? FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
		return location
	}()

	static let persistentPath = "persistent.chronicle"
	static let transientPath = "transient.chronicle"

	static let dateFormatter = ISO8601DateFormatter()

	static var logs: [Self] {
		try! FileManager.default.contentsOfDirectory(atPath: location.path).compactMap {
			Self.init(url: Self.location.appendingPathComponent($0))
		}
	}

	let url: URL
	let time: Date

	init?(url: URL) {
		self.url = url
		guard let time = Self.dateFormatter.date(from: url.lastPathComponent) else {
			return nil
		}
		self.time = time
	}

	static func create(persistentSize: Int, transientSize: Int) throws -> (Chronicle, Chronicle) {
		let url = Self.location.appendingPathComponent(Self.dateFormatter.string(from: Date())).appendingPathExtension("ensemblelog")
		try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
		let persistent = try Chronicle(url: url.appendingPathComponent(Self.persistentPath), bufferSize: persistentSize)
		let transient = try Chronicle(url: url.appendingPathComponent(Self.transientPath), bufferSize: transientSize)
		return (persistent, transient)
	}

	func delete() {
		try? FileManager.default.removeItem(at: url)
	}

	func archive() -> URL? {
		let archive = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(url.lastPathComponent).appendingPathExtension("aar")

		guard let output = ArchiveByteStream.fileStream(path: FilePath(archive.path), mode: .readWrite, options: .create, permissions: .init(rawValue: 0o644)) else {
			return nil
		}

		let compress = ArchiveByteStream.compressionStream(using: .lzfse, writingTo: output)!

		let input = ArchiveStream.encodeStream(writingTo: compress)!
		try! input.writeDirectoryContents(archiveFrom: FilePath(url.path), keySet: .init("TYP,PAT,DAT")!)

		try! input.close()
		try! compress.close()
		guard (try? output.close()) != nil else {
			return nil
		}

		return archive
	}

	var size: Int64 {
		func size(of item: URL) -> Int64 {
			guard let children = try? FileManager.default.contentsOfDirectory(atPath: item.path) else {
				return try! FileManager.default.attributesOfItem(atPath: item.path)[.size] as! Int64
			}
			return children.map {
				size(of: item.appendingPathComponent($0))
			}.reduce(0, +)
		}
		return size(of: url)
	}

	static func pruneLogs(count: Int) {
		let logs = Self.logs
		let keep = logs.sorted {
			$0.time < $1.time
		}.suffix(count)
		for log in logs[0..<keep.startIndex] {
			log.delete()
		}
	}

	var id: URL {
		url
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(url)
	}

	static var transferRepresentation: some TransferRepresentation {
		FileRepresentation(exportedContentType: .appleArchive) {
			return SentTransferredFile($0.archive()!)
		}
		// FileRepresentation seems to be broken?
		DataRepresentation(
			exportedContentType: .appleArchive,
			exporting: {
				try Data(contentsOf: $0.archive()!)
			}
		)
		.suggestedFileName("log.ensemblelog.aar")
	}

	static let (persistent, transient) = {
		@Preference(\.persistentLogSize)
		var persistentLogSize
		@Preference(\.transientLogSize)
		var transientLogSize

		return try! Log.create(persistentSize: persistentLogSize, transientSize: transientLogSize)
	}()

	static let persistentLogger = {
		try! Self.persistent.logger(name: "")
	}()

	static func logger(name: String) -> Logger {
		try! Self.transient.logger(name: name)
	}
}
