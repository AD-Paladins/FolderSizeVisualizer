# Swift Standards

## Language Version

Swift 6.0. The codebase uses Swift 6 features and enforces strict concurrency checking.

## Concurrency

- Use `actor` for shared mutable state (services, detectors, file I/O)
- Use `@MainActor` for ViewModels and UI-facing types
- Mark models as `Sendable` when they cross actor boundaries
- Use `async/await` — no callbacks or completion handlers in new code
- Use `Task` for lifecycle management, stored as `Task<Void, Never>?`

```swift
@Observable @MainActor final class ArtifactScanViewModel {
    private var scanTask: Task<Void, Never>?

    func startScan() {
        scanTask?.cancel()
        scanTask = Task {
            await service.scan()
        }
    }
}
```

## Type Design

- Prefer `struct` over `class` for models
- Use `enum` for closed sets of values, especially with `Codable + Sendable`
- Use `protocol` for service boundaries (e.g. `ArtifactDetector`, `ToolIntelligenceProvider`)
- Use `actor` for services, not `final class` with locks
- Use `@Observable` for ViewModels — not `ObservableObject`

## Naming

| Construct | Convention | Example |
|---|---|---|
| Types | PascalCase | `DeveloperArtifact` |
| Properties | camelCase | `sizeBytes` |
| Functions | camelCase | `startScan()` |
| Protocols | `...able`, `...ing`, or noun | `ArtifactDetector`, `AppCoordinating` |
| Enums + cases | PascalCase + camelCase | `ArtifactRiskLevel.safe` |
| Actors | noun | `FileSystemHelper` |

## File Organization

- One primary type per file
- File name matches the primary type name
- Extensions on the same type can go in the same file
- Use `// MARK: -` sections for organization

## Imports

- Order: system frameworks first, then blank line, then project types
- No `import UIKit` (macOS project)
- `import AppKit` only in files that need it, gated with `#if canImport(AppKit)`

## Property Wrappers

- `@Observable` for ViewModels
- `@Stored` / `@SecureStored` for UserDefaults / Keychain persistence
- `@State` for locally-owned ViewModel instances in views
- `@Bindable` for passing ViewModel between parent/child views
- `@Binding` for two-way communication (e.g. `isDeveloperModeEnabled`)
