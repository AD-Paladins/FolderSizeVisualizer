# Navigation Architecture

## Overview

This app uses **state-driven navigation** with `NavigationSplitView`. There is no coordinator pattern — views react to ViewModel state.

## NavigationSplitView (3-Column)

```swift
NavigationSplitView {
    ArtifactSidebarView  // selects viewModel.selectedTool
} content: {
    if let tool = selectedTool {
        ToolDetailView   // selects viewModel.selectedArtifact
    } else {
        DashboardView
    }
} detail: {
    if let artifact = selectedArtifact {
        ArtifactDetailView
    } else if selectedTool != nil {
        ContentUnavailableView("Select an Artifact")
    } else {
        ContentUnavailableView("Welcome")
    }
}
```

### Column Widths

| Column | Width |
|---|---|
| Sidebar | 250–320pt |
| Content | 450–620pt |
| Detail | 450–620pt |

## No NavigationStack

The app does **not** use `NavigationStack` or `NavigationPath`. Navigation is purely selection-driven within a split view. The legacy folder-based system has a manual `[URL]` stack with push/pop semantics handled by the view itself.

## State Ownership

- `ArtifactScanViewModel` owns `selectedTool` and `selectedArtifact`
- Views receive the ViewModel as `@Bindable`
- No `@EnvironmentObject` — explicit injection via initializer

## Intent Pattern

The app does NOT use an intent pattern. Views read ViewModel state directly. This is simpler for a single-window macOS utility but would not scale to a multi-flow app without refactoring.

## Legacy Navigation (Folder Mode)

The `ContentView` manages a manual `navigationStack: [URL]` array. `FolderDetailView` has a `scanFolder` callback for drill-down. This system is preserved but not actively developed.

## Deep Linking

Not implemented. The app has no URL scheme or deep linking.

## Related

- `../architecture/overview.md`
- `../architecture/modules.md`
