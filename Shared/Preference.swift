//
//  Preference.swift
//  Ensemble
//
//  Created by Saagar Jha on 2/6/24.
//

import SwiftUI

@propertyWrapper
struct Preference<T>: DynamicProperty {
	// Forces an update
	@State
	var value = false

	let key: String
	let defaultValue: T

	init(_ key: String, defaultValue: T) {
		self.key = key
		self.defaultValue = defaultValue
	}

	init(previewing value: T) {
		self.init("", defaultValue: value)
	}

	var wrappedValue: T {
		get {
			_ = value
			return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
		}
		nonmutating set {
			value.toggle()
			UserDefaults.standard.setValue(newValue, forKey: key)
		}
	}

	var projectedValue: Binding<T> {
		Binding(
			get: {
				wrappedValue
			},
			set: {
				wrappedValue = $0
			}
		)
	}

	var isSet: Bool {
		return UserDefaults.standard.value(forKey: key) != nil
	}

	func reset() {
		UserDefaults.standard.removeObject(forKey: key)
	}
}

@propertyWrapper
struct CodablePreference<T: Codable> {
	// Forces an update
	@State
	var value = false

	var key: String
	var defaultValue: T

	init(_ key: String, defaultValue: T) {
		self.key = key
		self.defaultValue = defaultValue
	}

	init(previewing value: T) {
		self.init("", defaultValue: value)
	}

	var wrappedValue: T {
		get {
			_ = value
			guard let data = UserDefaults.standard.object(forKey: key) as? Data else {
				return defaultValue
			}
			return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
		}
		nonmutating set {
			value.toggle()
			UserDefaults.standard.setValue(try! JSONEncoder().encode(newValue), forKey: key)
		}
	}

	var projectedValue: Binding<T> {
		Binding(
			get: {
				wrappedValue
			},
			set: {
				wrappedValue = $0
			}
		)
	}

	var isSet: Bool {
		UserDefaults.standard.value(forKey: key) != nil
	}

	func reset() {
		UserDefaults.standard.removeObject(forKey: key)
	}
}
