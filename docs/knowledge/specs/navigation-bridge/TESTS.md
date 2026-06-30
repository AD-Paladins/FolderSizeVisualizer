# Tests: Navigation Bridge

---

## Acceptance Criteria

- [ ] Given a SwiftUI view emits `.push(.userProfile(id:))`, the coordinator pushes the correct screen
- [ ] Given a SwiftUI view emits `.present(.legacySettings, style: .sheet)`, the coordinator presents modally
- [ ] Given a SwiftUI view emits `.dismiss`, the coordinator dismisses the current context
- [ ] No SwiftUI `View` file imports UIKit
- [ ] All previous ad-hoc bridge code is removed

---

## Unit Tests

```
CoordinatorTests
├── test_handle_pushIntent_callsNavigationControllerPush()
├── test_handle_presentSheetIntent_callsPresentWithSheetStyle()
├── test_handle_dismissIntent_callsDismiss()
└── test_handle_unknownDestination_doesNotCrash()
```

---

## Integration Tests

```
NavigationBridgeIntegrationTests
├── test_swiftUIView_canNavigateToUIKitScreen_viaCoordinator()
└── test_uikitScreen_canPresentSwiftUIScreen_viaHostingController()
```

---

## What Is Not Tested Here

- Internal SwiftUI view layout (covered by snapshot tests in the feature using the bridge)
- UIKit screen content (covered by that screen's own tests)
