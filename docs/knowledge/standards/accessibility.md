# Accessibility Standards

## Current State

This project has **very limited accessibility implementation**. Most interactive elements lack explicit accessibility labels, hints, or traits. VoiceOver support relies on SwiftUI defaults.

## Known Gaps

- No `.accessibilityLabel()` on interactive elements
- No `.accessibilityHint()` on any element
- No `.accessibilityHidden(true)` on decorative elements
- No `.accessibilityElement(children: .combine)` groupings
- No Dynamic Type testing infrastructure
- No dedicated accessibility identifiers

## What Exists

SF Symbols provide inherent accessibility via system image labels
`ContentUnavailableView` has descriptive empty states
Confirmation dialogs use `.confirmationDialog` (accessible by default)
`Label` with `systemImage` provides basic accessibility

## Minimum Requirements (Aspirational)

Every screen should pass these before merging:
- [ ] VoiceOver reads all interactive elements with a meaningful label
- [ ] No element has an empty or redundant accessibility label
- [ ] Touch targets are at least 44×44 pt
- [ ] Text scales correctly with Dynamic Type up to `accessibility3`
- [ ] Color is not the only means of conveying information

None of these are currently enforced or verified.

## SwiftUI Conventions (when implementing)

```swift
Image(systemName: "heart.fill")
    .accessibilityLabel("Add to favorites")

Divider()
    .accessibilityHidden(true)

HStack {
    Image(...)
    Text(title)
}
.accessibilityElement(children: .combine)
```

## Testing Accessibility

Run the Accessibility Inspector before merging any accessibility work. Snapshot tests are not yet used for accessibility variants.
