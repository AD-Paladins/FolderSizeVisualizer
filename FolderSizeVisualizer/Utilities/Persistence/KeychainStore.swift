//
//  KeychainStore.swift
//  FolderSizeVisualizer
//
//  A KeyValueStore backed by the system Keychain with JSON encoding for Codable values.
//

import Foundation
import Security

public struct KeychainConfiguration: Sendable {
    public enum Accessibility: Sendable {
        case whenUnlocked
        case afterFirstUnlock
        case whenPasscodeSetThisDeviceOnly
        case whenUnlockedThisDeviceOnly
        case afterFirstUnlockThisDeviceOnly

        var value: CFString {
            switch self {
            case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked
            case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
            case .whenPasscodeSetThisDeviceOnly: return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }
        }
    }

    public var service: String
    public var accessGroup: String?
    public var accessibility: Accessibility

    public init(service: String, accessGroup: String? = nil, accessibility: Accessibility = .whenUnlocked) {
        self.service = service
        self.accessGroup = accessGroup
        self.accessibility = accessibility
    }
}

public final class KeychainStore: KeyValueStore {
    private let config: KeychainConfiguration

    public init(config: KeychainConfiguration) {
        self.config = config
    }

    public func get<Value: Codable>(_ key: String, as type: Value.Type) throws -> Value? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: config.service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        if let accessGroup = config.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw StoreError.keychain(status: status) }
        guard let data = item as? Data else { return nil }

        // Attempt to decode JSON first; if that fails and Value == Data, return raw
        if Value.self == Data.self, let v = data as? Value { return v }
        return try StoreCoding.decode(data, as: Value.self)
    }

    public func set<Value: Codable>(_ value: Value?, for key: String) throws {
        if value == nil {
            try remove(key)
            return
        }

        let data: Data
        switch value {
        case let v as Data:
            data = v
        default:
            data = try StoreCoding.encode(value!)
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: config.service,
            kSecAttrAccount as String: key
        ]
        if let accessGroup = config.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: config.accessibility.value
        ]

        // Try update first
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            // Add new item
            var addQuery = query
            attributes.forEach { addQuery[$0.key] = $0.value }
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw StoreError.keychain(status: addStatus) }
        } else if status != errSecSuccess {
            throw StoreError.keychain(status: status)
        }
    }

    public func remove(_ key: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: config.service,
            kSecAttrAccount as String: key
        ]
        if let accessGroup = config.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw StoreError.keychain(status: status) }
    }
}
// MARK: - Concurrency

extension KeychainStore: @unchecked Sendable {}

