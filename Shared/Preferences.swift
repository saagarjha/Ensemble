//
//  Preferences.swift
//  Shared
//
//  Created by Saagar Jha on 4/17/24.
//

struct _Preference {
	var persistedHistoricalLogs = Preference("PersistedHistoricalLogs", defaultValue: 10)
	var persistentLogSize = Preference("PersistedLogSize", defaultValue: 1 << 10)
	var transientLogSize = Preference("TransientLogSize", defaultValue: 1 << 20)
}

extension Preference {
	init(_ preference: KeyPath<_Preference, Preference<T>>) {
		self = _Preference()[keyPath: preference]
	}
}
