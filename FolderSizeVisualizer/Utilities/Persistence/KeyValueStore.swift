//
//  KeyValueStore.swift
//  FolderSizeVisualizer
//
//  A small, scalable abstraction for storing and retrieving values
//  from different backends (UserDefaults, Keychain, etc.).
//

import Foundation
import Security

// MARK: - Errors

public enum StoreError: Error, LocalizedError {
    case encodingFailed(underlying: Error)
    case decodingFailed(underlying: Error)
    case keychain(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let underlying):
            return "Encoding failed: \(underlying.localizedDescription)"
        case .decodingFailed(let underlying):
            return "Decoding failed: \(underlying.localizedDescription)"
        case .keychain(let status):
            return "Keychain error: \(status)"
        }
    }
}

// MARK: - Typed keys

/// A strongly-typed key for values stored in `UserDefaults` (or any key-value store).
public struct AppKey<Value>: Hashable, Sendable where Value: Codable & Sendable {
    public static func == (lhs: AppKey<Value>, rhs: AppKey<Value>) -> Bool {
        // Compare both the key name and the generic Value type to avoid collisions
        return lhs.name == rhs.name && (Value.self == Value.self)
    }

    // Include the generic type identity to distinguish keys with the same name but different Value types
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(ObjectIdentifier(Value.self))
    }

    public let name: String
    public let defaultValue: Value

    public init(_ name: String, default defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

/// A strongly-typed key for Keychain values.
public struct SecureKey<Value: Codable>: Hashable, Sendable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }
}

// MARK: - Protocol

/// A generic key-value store.
public protocol KeyValueStore: Sendable {
    /// Retrieve a value for the given key.
    func get<Value: Codable>(_ key: String, as type: Value.Type) throws -> Value?

    /// Store a value for the given key. Pass `nil` to remove.
    func set<Value: Codable>(_ value: Value?, for key: String) throws

    /// Remove a value for the given key.
    func remove(_ key: String) throws
}

// MARK: - Coding helpers

enum StoreCoding {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()

    static func encode<Value: Codable>(_ value: Value) throws -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw StoreError.encodingFailed(underlying: error)
        }
    }

    static func decode<Value: Codable>(_ data: Data, as type: Value.Type) throws -> Value {
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            throw StoreError.decodingFailed(underlying: error)
        }
    }
}

