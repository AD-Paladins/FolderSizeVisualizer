//
//  StoredPropertyWrappers.swift
//  FolderSizeVisualizer
//
//  Ergonomic property wrappers for UserDefaults and Keychain backed values.
//

import Foundation

// MARK: - @Stored (UserDefaults)

@propertyWrapper
public struct Stored<Value: Codable & Sendable> {
    private let key: AppKey<Value>
    private let store: KeyValueStore

    public init(_ key: AppKey<Value>, store: KeyValueStore = UserDefaultsStore()) {
        self.key = key
        self.store = store
    }

    public var wrappedValue: Value {
        get {
            (try? store.get(key.name, as: Value.self)) ?? key.defaultValue
        }
        nonmutating set {
            try? store.set(newValue, for: key.name)
        }
    }
}

// MARK: - @SecureStored (Keychain)

@propertyWrapper
public struct SecureStored<Value: Codable> {
    private let key: SecureKey<Value>
    private let store: KeyValueStore

    public init(_ key: SecureKey<Value>, config: KeychainConfiguration) {
        self.key = key
        self.store = KeychainStore(config: config)
    }

    public init(_ key: SecureKey<Value>, store: KeyValueStore) { // for testing/mocking
        self.key = key
        self.store = store
    }

    public var wrappedValue: Value? {
        get { try? store.get(key.name, as: Value.self) }
        nonmutating set { try? store.set(newValue, for: key.name) }
    }
}

// MARK: - Convenience keys

public enum AppKeys {
    // Example keys to show usage; replace or extend as needed.
    public static let hasOnboarded = AppKey<Bool>("hasOnboarded", default: false)
    public static let preferredUnit = AppKey<String>("preferredUnit", default: "MB")
    public static let suppressGlobalDeletionWarning = AppKey<Bool>("suppressGlobalDeletionWarning", default: false)
}

public enum SecureKeys {
    public static let apiToken = SecureKey<String>("apiToken")
}
