# Persistence README

This folder contains a small, scalable storage layer for UserDefaults and Keychain. It is composed of:

- `KeyValueStore.swift` – protocol and typed keys used across stores
- `UserDefaultsStore.swift` – UserDefaults-backed implementation
- `KeychainStore.swift` or `KeychainStore-Persistence.swift` – Keychain-backed implementation
- `StoredPropertyWrappers.swift` – ergonomic property wrappers `@Stored` and `@SecureStored`

Use these components to store preferences and secrets in a safe, testable, and ergonomic way.

---

## When to use what
- Use UserDefaults for non-sensitive preferences and small values (flags, UI preferences).
- Use Keychain for secrets and credentials (tokens, passwords, sensitive identifiers).

All values must conform to `Codable`. Primitives and `Data` are stored natively in `UserDefaults`; complex types are JSON-encoded.

---

## Core Concepts

### Typed Keys
- `AppKey<Value>` – strongly-typed keys for `UserDefaults` with a default value.
- `SecureKey<Value>` – strongly-typed keys for Keychain.

```swift
public enum AppKeys {
    public static let hasOnboarded = AppKey<Bool>("hasOnboarded", default: false)
    public static let preferredUnit = AppKey<String>("preferredUnit", default: "MB")
}

public enum SecureKeys {
    public static let apiToken = SecureKey<String>("apiToken")
}
```

KeyValueStore Protocol
Both stores conform to this minimal protocol:
```swift
public protocol KeyValueStore: Sendable {
    func get<Value: Codable>(_ key: String, as type: Value.Type) throws -> Value?
    func set<Value: Codable>(_ value: Value?, for key: String) throws
    func remove(_ key: String) throws
}
```
⸻

Quick Start

UserDefaults via @Stored
```swift
@Stored(AppKeys.hasOnboarded) var hasOnboarded: Bool
@Stored(AppKeys.preferredUnit) var preferredUnit: String

hasOnboarded = true
print(preferredUnit) // "MB" by default
```

Keychain via @SecureStored
```swift
let keychainConfig = KeychainConfiguration(
    service: "com.yourcompany.foldersizevisualizer",
    accessGroup: nil,
    accessibility: .whenUnlocked
)

@SecureStored(SecureKeys.apiToken, config: keychainConfig)
var apiToken: String?

apiToken = "secret-token"
print(apiToken ?? "<nil>")
```
⸻

## Using the Stores Directly

### UserDefaultsStore
```swift
let defaults = UserDefaultsStore()
try defaults.set(true, for: "someFlag")
let flag: Bool? = try defaults.get("someFlag", as: Bool.self)
try defaults.remove("someFlag")
```

#### Target a custom suite or app group if needed:
```swift
let defaults = UserDefaultsStore(suiteName: "group.com.yourcompany.shared")
```

#### KeychainStore
```swift
let config = KeychainConfiguration(
    service: "com.yourcompany.foldersizevisualizer",
    accessibility: .whenUnlocked
)
let keychain = KeychainStore(config: config)

try keychain.set("secret-token", for: "apiToken")
let token: String? = try keychain.get("apiToken", as: String.self)
try keychain.remove("apiToken")
```

⸻

## Keychain Configuration
public struct KeychainConfiguration: Sendable {
    public enum Accessibility: Sendable {
        case whenUnlocked
        case afterFirstUnlock
        case whenPasscodeSetThisDeviceOnly
        case whenUnlockedThisDeviceOnly
        case afterFirstUnlockThisDeviceOnly
    }

    public var service: String          // reverse-DNS identifier unique to your app/feature
    public var accessGroup: String?     // set if using Keychain Sharing
    public var accessibility: Accessibility
}

**Tips:**
• Prefer .when​Unlocked for most tokens.
• Use This​Device​Only variants if you do not need iCloud Keychain sync.
• Set access​Group for multi-target/app sharing (requires entitlements).


⸻

## Dependency Injection & Testing
Because Key​Value​Store is a protocol, you can inject a mock store for tests.
```swift
struct InMemoryStore: KeyValueStore {
    private var storage = [String: Data]()

    func get<Value: Codable>(_ key: String, as type: Value.Type) throws -> Value? {
        guard let data = storage[key] else { return nil }
        return try StoreCoding.decode(data, as: Value.self)
    }

    func set<Value: Codable>(_ value: Value?, for key: String) throws {
        if let value {
            storage[key] = try StoreCoding.encode(value)
        } else {
            storage.removeValue(forKey: key)
        }
    }

    func remove(_ key: String) throws {
        storage.removeValue(forKey: key)
    }
}

@SecureStored(SecureKeys.apiToken, store: InMemoryStore())
var testToken: String?
```

⸻

## Error Handling
• The property wrappers swallow errors to keep UI code simple.
• When you need to surface errors, use the stores directly and handle Store​Error​.encoding​Failed, Store​Error​.decoding​Failed, and Store​Error​.keychain.

⸻

## Concurrency Notes
• Stores are marked @unchecked ​Sendable. Prefer to call them from a dedicated actor or the main actor in UI flows.

⸻

## Migration Tips
• User​Defaults​Store reads primitives directly; complex types are JSON-encoded.
• Keychain values are JSON-encoded unless you write Data.
• If you change encoding for a key, add a one-time migration path that tries multiple decoding strategies.

⸻

## Example: ViewModel + SwiftUI
```swift
final class SettingsViewModel: ObservableObject {
    @Stored(AppKeys.hasOnboarded) var hasOnboarded: Bool
    @Stored(AppKeys.preferredUnit) var preferredUnit: String

    private let keychainConfig = KeychainConfiguration(
        service: "com.yourcompany.foldersizevisualizer",
        accessibility: .whenUnlocked
    )

    @SecureStored(SecureKeys.apiToken, config: keychainConfig)
    var apiToken: String?
}

import SwiftUI

struct SettingsView: View {
    @StateObject private var model = SettingsViewModel()

    var body: some View {
        Form {
            Toggle("Completed Onboarding", isOn: $model.hasOnboarded)

            Picker("Preferred Unit", selection: $model.preferredUnit) {
                Text("MB").tag("MB")
                Text("GB").tag("GB")
            }

            Section("API Token") {
                SecureField("Token", text: Binding(
                    get: { model.apiToken ?? "" },
                    set: { model.apiToken = $0.isEmpty ? nil : $0 }
                ))
                Button("Clear Token") { model.apiToken = nil }
            }
        }
    }
}
```

⸻

## Security Checklist
• Do not store secrets in User​Defaults; use Keychain.
• Choose the least-permissive Accessibility that fits your UX.
• Prefer This​Device​Only if you don’t need iCloud Keychain sync.
• Use a unique service string for your app or feature area.
• Configure access​Group and entitlements if sharing across apps/targets.

⸻

## Troubleshooting
• If you see duplicate type errors for Keychain​Store/Keychain​Configuration, ensure you only include one Keychain implementation file (either Keychain​Store​.swift or KeychainStore.swift􀰓).
• For Keychain err​Sec​Auth​Failed or -34018, check entitlements, access group configuration, and test on a device or a simulator with Keychain enabled.
• For decoding errors, confirm your type conforms to Codable and hasn’t changed incompatibly without migration.

⸻

## Extending the System
• Implement new stores by conforming to Key​Value​Store (e.g., encrypted file store, cloud-backed store).
• Add new app keys centrally (extend App​Keys/Secure​Keys) to keep key names consistent.
