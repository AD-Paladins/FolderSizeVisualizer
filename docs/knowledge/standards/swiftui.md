# SwiftUI Standards

## View Structure

- One `View` per file. File name matches the type name exactly.
- Keep `body` short. If `body` exceeds ~40 lines, extract sub-views.
- Private sub-views go in the same file as `private struct`, not in separate files.
- Preview at the bottom of the same file using `#Preview`.

```swift
struct UserProfileView: View {
    var body: some View {
        VStack {
            header
            content
        }
    }
}

// MARK: - Private

private extension UserProfileView {
    var header: some View { ... }
    var content: some View { ... }
}

#Preview {
    UserProfileView()
}
```

---

## View Models

- Use `@Observable` (iOS 17+) or `ObservableObject` for view models.
- View models are named `<Feature>ViewModel`.
- View models do not import SwiftUI. They are pure Swift.
- One view model per screen. Shared state goes in a dedicated service, not a shared view model.

---

## Modifiers

- Extract repeated modifier chains into `ViewModifier` or `View` extensions.
- Name custom modifiers as verbs: `.cardStyle()`, `.highlightOnFocus()`.

---

## Navigation (SwiftUI side)

- Use `NavigationStack` for push navigation. Do not use the deprecated `NavigationView`.
- Pass `NavigationPath` from a coordinator or view model — do not let views own the path directly in cross-boundary flows.
- Emit intent values for navigation; do not call bridge code from inside `body`.

---

## Previews

- Every view must have at least one preview.
- Provide a preview for the error/empty state if the view has one.
- Use mock data — never live network calls in previews.

---

## What to Avoid

| Anti-pattern | Preferred alternative |
|---|---|
| `AnyView` wrapping | `@ViewBuilder` with typed branches |
| `EnvironmentObject` for single-branch data | Explicit initializer injection |
| Logic inside `body` | Computed properties or view model methods |
| `UIKit` import in a `View` file | Move bridge code to `Bridge/` group |
