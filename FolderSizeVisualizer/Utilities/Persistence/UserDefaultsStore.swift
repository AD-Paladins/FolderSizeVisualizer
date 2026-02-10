//
//  UserDefaultsStore.swift
//  FolderSizeVisualizer
//
//  A KeyValueStore backed by UserDefaults with JSON encoding for Codable values.
//

import Foundation

public final class UserDefaultsStore: KeyValueStore {
    private let defaults: UserDefaults
    private let suiteName: String?

    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
        if let suiteName {
            self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.defaults = .standard
        }
    }

    public func get<Value: Codable>(_ key: String, as type: Value.Type) throws -> Value? {
        // Handle simple primitive bridging to avoid JSON round-trip when possible
        if Value.self == String.self, let v = defaults.string(forKey: key) as? Value { return v }
        if Value.self == Bool.self, let v = defaults.object(forKey: key) as? Value { return v }
        if Value.self == Int.self, let v = defaults.object(forKey: key) as? Value { return v }
        if Value.self == Double.self, let v = defaults.object(forKey: key) as? Value { return v }
        if Value.self == Float.self, let v = defaults.object(forKey: key) as? Value { return v }
        if Value.self == Data.self, let v = defaults.data(forKey: key) as? Value { return v }

        guard let data = defaults.data(forKey: key) else { return nil }
        return try StoreCoding.decode(data, as: Value.self)
    }

    public func set<Value: Codable>(_ value: Value?, for key: String) throws {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }

        // Store primitives directly
        switch value {
        case let v as String: defaults.set(v, forKey: key)
        case let v as Bool: defaults.set(v, forKey: key)
        case let v as Int: defaults.set(v, forKey: key)
        case let v as Double: defaults.set(v, forKey: key)
        case let v as Float: defaults.set(v, forKey: key)
        case let v as Data: defaults.set(v, forKey: key)
        default:
            let data = try StoreCoding.encode(value)
            defaults.set(data, forKey: key)
        }
    }

    public func remove(_ key: String) throws {
        defaults.removeObject(forKey: key)
    }
}

// MARK: - Concurrency

extension UserDefaultsStore: @unchecked Sendable {}

