//
//  ContentView.swift
//  macOS
//
//  Created by Saagar Jha on 10/8/23.
//

import AppleConnect
import SwiftUI

let service = "_\(Bundle.main.name.lowercased())._tcp"

struct ContentView: View {
	@State
	var pairingCode: String = Self.generatePairingCode()

	@State
	var remote: Remote?
	@State
	var askForPermissions = false
	@State
	var prewarmedHelper = false

	@Preference("SuppressPermissionsView", defaultValue: false)
	var suppressPermissionsView

	init() {
		_askForPermissions = State(initialValue: !Permission.allCases.allSatisfy(\.enabled) && !suppressPermissionsView)
	}

	var body: some View {
		HStack(spacing: 50) {
			Image(systemName: remote == nil ? "visionpro" : "macbook.and.visionpro")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 500)
				.padding(.leading, remote == nil ? -250 : -200)
			VStack(spacing: 20) {
				if let remote {
					VStack(alignment: .leading) {
						Text("Connected to \(remote.name)")
							.font(.title)
					}
					HStack {
						Button("Disconnect") {
							remote.connection.connection.close()
							self.remote = nil
						}
					}
				} else {
					VStack(alignment: .leading, spacing: 8) {
						Text("Waiting to connect…")
							.font(.title)
						Text("Launch \(Bundle.main.name) on your Apple Vision Pro and enter this pairing code when prompted.")
					}
					let characters = Array(pairingCode)
					HStack(spacing: 20) {
						ForEach(characters.indices, id: \.self) {
							Text(characters[$0].description)
								.font(.system(size: 64))
								.monospacedDigit()
						}
					}
					HStack {
						Button("Regenerate") {
							pairingCode = Self.generatePairingCode()
						}
					}
				}
			}
			.task {
				do {
					for try await connection in Connection.advertise(forServiceType: service, key: Data()) {
						let connection = try await Connection(connection: connection)
						var remote = Remote(connection: connection)
						if try await remote.handshake() {
							self.remote = remote
						}
						break
					}
				} catch {
				}
			}
		}
		.padding(40)
		.frame(width: 800, height: 400)
		.sheet(isPresented: $askForPermissions) {
			PermissionsView(askForPermissions: $askForPermissions, suppressPermissionsView: _suppressPermissionsView)
		}
		.onChange(of: askForPermissions, initial: true) {
			// FIXME: This races with the first code that calls accessibility
			// APIs, and this is an awful place to put it to boot.
			Task {
				if !prewarmedHelper,
					Permission.helper.supported,
					Permission.helper.enabled
				{
					prewarmedHelper = await Permission.prewarmHelper()
				}
			}
		}
	}

	static func generatePairingCode() -> String {
		(1...6).map { _ in String("0123456789".randomElement()!) }.joined()
	}
}

#Preview {
	ContentView()
}
