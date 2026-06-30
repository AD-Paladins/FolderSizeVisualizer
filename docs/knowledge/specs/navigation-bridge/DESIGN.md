# Design: Navigation Bridge

> Status: Draft — open questions must be resolved before implementation begins.

---

## Core Types

```swift
// Intent emitted by SwiftUI views — no UIKit dependency
enum NavigationIntent {
    case push(Destination)
    case present(Destination, style: PresentationStyle)
    case dismiss
}

enum Destination {
    // Add cases as features are bridged
    // e.g. case userProfile(userID: String)
    //      case legacySettings
}

enum PresentationStyle {
    case sheet
    case fullScreen
}
```

---

## Coordinator Interface

```swift
protocol AppCoordinating: AnyObject {
    func handle(_ intent: NavigationIntent)
}
```

SwiftUI views receive a coordinator via the environment or initializer. They call `handle(_:)` — they never import UIKit.

---

## Data Flow

```
SwiftUI View
    │ emits NavigationIntent
    ▼
AppCoordinator (UIKit)
    │ interprets Destination
    ├─ SwiftUI target → UIHostingController → push/present
    └─ UIKit target  → UIViewController    → push/present
```

---

## Environment Key (SwiftUI side)

```swift
struct CoordinatorKey: EnvironmentKey {
    static let defaultValue: (any AppCoordinating)? = nil
}

extension EnvironmentValues {
    var coordinator: (any AppCoordinating)? {
        get { self[CoordinatorKey.self] }
        set { self[CoordinatorKey.self] = newValue }
    }
}
```

---

## Open Questions

- [ ] Should `Destination` be a flat enum or nested by feature group?
- [ ] Who owns `AppCoordinator` — the scene delegate or a root coordinator?
- [ ] How does deep linking map to `Destination` cases?
