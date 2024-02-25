#!/usr/bin/env DYLD_FRAMEWORK_PATH=/System/Library/Frameworks swift
// ^ Temporary workaround for https://github.com/apple/swift/issues/68785

import CryptoKit
import Foundation

struct API {
	struct _API {
		let header: String
		let issuerID: String
		let privateKey: P256.Signing.PrivateKey

		init(key: Data, keyID: String, issuerID: String) throws {
			header = try JSONEncoder().encode([
				"alg": "ES256",
				"kid": keyID,
				"typ": "JWT",
			]).base64EncodedString().filter {
				$0 != "="
			}

			self.issuerID = issuerID

			let pem = String(data: key, encoding: .utf8)!
			privateKey = try P256.Signing.PrivateKey(pemRepresentation: pem)
		}

		func generateJWT() throws -> String {
			let payload = try JSONSerialization.data(
				withJSONObject: [
					"iss": issuerID,
					"iat": Date.now.timeIntervalSince1970,
					"exp": Date.now.addingTimeInterval(2 * 60).timeIntervalSince1970,
					"aud": "appstoreconnect-v1",
				] as [String: Any]
			).base64EncodedString().filter {
				$0 != "="
			}

			let signature = try privateKey.signature(for: Data((header + "." + payload).utf8)).rawRepresentation.base64EncodedString().filter {
				$0 != "="
			}

			return header + "." + payload + "." + signature
		}

		// Debugging helper
		static func decode<T: Decodable>(_: T.Type, from data: Data, endpoint: String) throws -> T {
			do {
				return try JSONDecoder().decode(T.self, from: data)
			} catch {
				fputs("Failed to decode response from \(endpoint)! Data:\n", stderr)
				try FileHandle.standardError.write(contentsOf: data)
				try FileHandle.standardError.synchronize()
				throw error
			}
		}

		func _getRequest(endpoint: String) async throws -> Data {
			var request = URLRequest(url: URL(string: endpoint)!)
			request.addValue("Bearer \(try generateJWT())", forHTTPHeaderField: "Authorization")
			return try await URLSession.shared.data(for: request).0
		}

		func getRequest<T: Codable>(endpoint: String, parsing response: T.Type) async throws -> T {
			var request = URLRequest(url: URL(string: endpoint)!)
			request.addValue("Bearer \(try generateJWT())", forHTTPHeaderField: "Authorization")
			return try Self.decode(T.self, from: await URLSession.shared.data(for: request).0, endpoint: endpoint)
		}

		func _postyRequest(endpoint: String, method: String = "POST", object: Encodable) async throws -> Data {
			var request = URLRequest(url: URL(string: endpoint)!)
			request.addValue("Bearer \(try generateJWT())", forHTTPHeaderField: "Authorization")
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpMethod = method
			request.httpBody = try JSONEncoder().encode(object)
			return try await URLSession.shared.data(for: request).0
		}

		struct Response<T: Codable>: Codable {
			struct Links: Codable {
				let next: String?
			}

			let data: [T]
			let links: Links
		}

		func pagedGetRequest<T: Codable>(endpoint: String, parsing data: T.Type) async throws -> [T] {
			var result = [T]()
			var nextEndpoint = Optional.some(endpoint)
			while let endpoint = nextEndpoint {
				let next = try await getRequest(endpoint: endpoint, parsing: Response<T>.self)
				result.append(contentsOf: next.data)
				nextEndpoint = next.links.next
			} 
			return result
		}
	}

	let _api: _API

	init(key: Data, keyID: String, issuerID: String) throws {
		_api = try .init(key: key, keyID: keyID, issuerID: issuerID)
	}

	struct App: Codable {
		struct Attributes: Codable {
			let bundleId: String
		}

		let id: String
		let attributes: Attributes
	}

	func apps() async throws -> [App] {
		try await _api.pagedGetRequest(endpoint: "https://api.appstoreconnect.apple.com/v1/apps", parsing: App.self)
	}

	struct AppBuild: Codable {
		struct Attributes: Codable {
			let version: String
		}

		let id: String
		let attributes: Attributes
	}

	func builds(forAppID appID: String) async throws -> [AppBuild] {
		try await _api.pagedGetRequest(endpoint: "https://api.appstoreconnect.apple.com/v1/apps/\(appID)/builds", parsing: AppBuild.self)
	}

	struct PrereleaseVersion: Codable {
		struct Attributes: Codable {
			enum Platform: String, Codable {
				case IOS
				case MAC_OS
				case TV_OS
				case VISION_OS
			}

			let platform: Platform
		}

		let id: String
		let attributes: Attributes
	}

	func prereleaseVersion(forBuildID buildID: String) async throws -> PrereleaseVersion {
		struct Response: Codable {
			let data: PrereleaseVersion
		}

		return try await _api.getRequest(endpoint: "https://api.appstoreconnect.apple.com/v1/builds/\(buildID)/preReleaseVersion?fields[preReleaseVersions]=platform", parsing: Response.self).data
	}

	struct Build: Codable {
		struct Attributes: Codable {
			enum ProcessingState: String, Codable {
				case PROCESSING
				case FAILED
				case INVALID
				case VALID
			}

			let processingState: ProcessingState
		}

		let id: String
		let attributes: Attributes
	}

	func build(forBuildID buildID: String) async throws -> Build {
		struct Response: Codable {
			let data: Build
		}

		return try await _api.getRequest(endpoint: "https://api.appstoreconnect.apple.com/v1/builds/\(buildID)", parsing: Response.self).data
	}

	struct BetaLocalization: Codable {
		struct Attributes: Codable {
			let whatsNew: String?
			let locale: String
		}

		let id: String
		let attributes: Attributes
	}

	func betaLocalizations(forBuildID buildID: String) async throws -> [BetaLocalization] {
		try await _api.pagedGetRequest(endpoint: "https://api.appstoreconnect.apple.com/v1/builds/\(buildID)/betaBuildLocalizations", parsing: BetaLocalization.self)
	}

	func updateWhatsNew(_ whatsNew: String, forBetaLocalizationID betaLocalizationID: String) async throws {
		struct Request: Encodable {
			struct BetaLocalizationUpdate: Encodable {
				struct Attributes: Encodable {
					let whatsNew: String
				}

				let id: String
				let type = "betaBuildLocalizations"
				let attributes: Attributes
			}

			let data: BetaLocalizationUpdate
		}
		let request = Request(data: .init(id: betaLocalizationID, attributes: .init(whatsNew: whatsNew)))
		_ = try await _api._postyRequest(endpoint: "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations/\(betaLocalizationID)", method: "PATCH", object: request)
	}

	struct BetaGroup: Codable {
		struct Attributes: Codable {
			let name: String
			let isInternalGroup: Bool
		}

		let id: String
		let attributes: Attributes
	}

	func betaGroups() async throws -> [BetaGroup] {
		try await _api.pagedGetRequest(endpoint: "https://api.appstoreconnect.apple.com/v1/betaGroups", parsing: BetaGroup.self)
	}

	struct BetaGroupBuild: Codable {
		let id: String
	}

	func builds(forBetaGroupID betaGroupID: String) async throws -> [BetaGroupBuild] {
		try await _api.pagedGetRequest(endpoint: "https://api.appstoreconnect.apple.com/v1/betaGroups/\(betaGroupID)/builds", parsing: BetaGroupBuild.self)
	}

	func setBuilds(buildIDs: [String], toBetaGroupID betaGroupID: String) async throws {
		struct Request: Encodable {
			struct BetaGroupBuild: Encodable {
				let id: String
				let type = "builds"
			}

			let data: [BetaGroupBuild]
		}
		let request = Request(data: buildIDs.map(Request.BetaGroupBuild.init(id:)))
		_ = try await _api._postyRequest(endpoint: "https://api.appstoreconnect.apple.com/v1/betaGroups/\(betaGroupID)/relationships/builds", object: request)
	}

	func submitBuildForReview(buildID: String) async throws {
		struct Request: Encodable {
			struct Submission: Encodable {
				struct Relationships: Encodable {
					struct Build: Encodable {
						struct Data: Encodable {
							let id: String
							let type = "builds"
						}

						let data: Data
					}

					let build: Build
				}

				let type = "betaAppReviewSubmissions"
				let relationships: Relationships
			}

			let data: Submission
		}
		let request = Request(data: .init(relationships: .init(build: .init(data: .init(id: buildID)))))
		_ = try await _api._postyRequest(endpoint: "https://api.appstoreconnect.apple.com/v1/betaAppReviewSubmissions", object: request)
	}
}

// Turn off buffering so GitHub Actions prints output immediately
setbuf(stdout, nil)

let build = CommandLine.arguments[1]
print("Performing steps for build \(build)...")
print()

let _key = ProcessInfo.processInfo.environment["AUTHENTICATION_KEY"]!
let keyID = ProcessInfo.processInfo.environment["AUTHENTICATION_KEY_ID"]!
let issuerID = ProcessInfo.processInfo.environment["AUTHENTICATION_KEY_ISSUER_ID"]!
print("Loading authentication from \(_key), keyID \(keyID), issuerID \(issuerID)...", terminator: "")

let key = try Data(contentsOf: URL(fileURLWithPath: _key))
let api = try API(key: key, keyID: keyID, issuerID: issuerID)
print("Loaded")

print("Listing apps...", terminator: "")
let apps = try await api.apps()
let appID = apps.first {
	$0.attributes.bundleId == "com.saagarjha.MacCast"
}!.id
print("Found app ID \(appID)")

// Even though we should've uploaded builds before running this script, they
// might not be listed yet.
print("Waiting for builds to become available...")
var builds: [API.AppBuild]
repeat {
	print("Listing builds...", terminator: "")
	builds = try await api.builds(forAppID: appID).filter {
		$0.attributes.version == build
	}
	print("Found \(builds.count) builds")
	guard builds.count != 2 else {
		break
	}
	try await Task.sleep(for: .seconds(10))
} while true

var buildPlatforms = [API.PrereleaseVersion]()
for build in builds {
	print("Looking up platform for build \(build.id)...", terminator: "")
	let version = try await api.prereleaseVersion(forBuildID: build.id)
	buildPlatforms.append(version)
	print("\(version.attributes.platform.rawValue)")
}

let macOSBuild = builds[buildPlatforms.firstIndex { 
	$0.attributes.platform == .MAC_OS
}!]
let visionOSBuild = builds[buildPlatforms.firstIndex {
	$0.attributes.platform == .VISION_OS
}!]

print("Waiting for builds to process...")

func waitForBuildToProcess(buildID: String) async throws -> API.Build.Attributes.ProcessingState {
	while true {
		let build = try await api.build(forBuildID: buildID)
		print("Build \(buildID) is \(build.attributes.processingState.rawValue)!")
		guard build.attributes.processingState == .PROCESSING else {
			return build.attributes.processingState
		}
		try await Task.sleep(for: .seconds(30))
	}
}

let (macOSStatus, visionOSStatus) = (try await waitForBuildToProcess(buildID: macOSBuild.id), try await waitForBuildToProcess(buildID: visionOSBuild.id))
precondition(macOSStatus == .VALID)
precondition(visionOSStatus == .VALID)

print("Generating notes...", terminator: "")
let output = Pipe()
let process = Process()
process.executableURL = URL(fileURLWithPath: "Release/generate_notes.sh")
process.standardOutput = output
try process.run()
process.waitUntilExit()
let notes = String(data: try output.fileHandleForReading.readToEnd()!, encoding: .utf8)!
print("Generated")
print("Notes:")
for line in notes.split(separator: "\n") {
	print("\t\(line)")
}

print("Listing beta groups...", terminator: "")
let betaGroup = try await api.betaGroups().first {
	$0.attributes.name == "Test" && !$0.attributes.isInternalGroup
}!
print("Found beta group \(betaGroup.id)")

print("Finding old beta builds in group...", terminator: "")
let betaBuilds = try await api.builds(forBetaGroupID: betaGroup.id)
print("Found \(betaBuilds.count) builds")

print("Adding new builds to group...", terminator: "")
try await api.setBuilds(buildIDs: betaBuilds.map(\.id) + [macOSBuild.id, visionOSBuild.id], toBetaGroupID: betaGroup.id)
print("Added")

for build in [macOSBuild, visionOSBuild] {
	print("Finding localization ID for build \(build.id)...", terminator: "")
	let localization = try await api.betaLocalizations(forBuildID: build.id).first {
		$0.attributes.locale == "en-US"
	}!
	print("Found")

	print("Updating notes for \(localization.id)...", terminator: "")
	try await api.updateWhatsNew(notes, forBetaLocalizationID: localization.id)
	print("Updated")

	print("Submitting build \(build.id) for review...", terminator: "")
	try await api.submitBuildForReview(buildID: build.id)
	print("Submitted!")
}

print()
print("Finished!")
