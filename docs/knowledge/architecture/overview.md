# Architecture Overview

## Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI 5 (macOS 15+) |
| State | `@Observable` macro + `@MainActor` |
| Concurrency | Swift actors for service layer |
| Navigation | `NavigationSplitView` (3-column) |
| Persistence | `UserDefaults` + Keychain via protocol abstraction |
| AI | Apple Intelligence (`SystemLanguageModel`, macOS 26+) |
| Tests | Swift Testing framework (unit), XCTest (UI) |

## No UIKit

This is a **pure SwiftUI macOS application**. UIKit is not used. AppKit is used only for:
- `NSAlert`, `NSOpenPanel`, `NSWorkspace` (file system dialogs)
- `NSPasteboard` (copy to clipboard)
- `NSCursor`, `NSColor` (UI details)
- `NSApplication` notifications

All AppKit usage is gated behind `#if canImport(AppKit)`.

## Pattern: MVVM + Actor Services

```
User Action
  -> ArtifactScanViewModel (@Observable @MainActor)
    -> ArtifactScanService (actor, orchestrator)
      -> [XcodeArtifactDetector, SimulatorArtifactDetector, ...] (actors)
        -> FileSystemHelper (actor, file I/O)
```

- ViewModels are `@Observable` + `@MainActor`
- Services and detectors are `actor` types — run on background threads
- Data crosses the boundary via `Sendable` models
- Progress is reported via `@Sendable` closures that hop to `MainActor`

## Two Parallel Systems

The app has legacy (folder-based) and current (tool/artifact-based) systems, switchable via `isDeveloperMode` toggle:

| | Legacy | Current |
|---|---|---|
| ViewModel | `ScanViewModel` | `ArtifactScanViewModel` |
| Model | `FolderEntry` | `DeveloperArtifact` |
| Service | `FolderScanner` | `ArtifactScanService` |
| Navigation | Manual URL stack | Selection-driven |
| Status | Preserved, not default | Default |

## NavigationSplitView 3-Column Layout

```
Sidebar (tool list)
  |-> Content (dashboard OR tool detail + artifact list)
      |-> Detail (artifact detail)
```

Navigation is state-driven — views react to `selectedTool` / `selectedArtifact` on the ViewModel. No coordinator pattern.

## Dependencies

Zero third-party dependencies. Only system frameworks: SwiftUI, Foundation, AppKit, OSLog, Security, Testing, XCTest.

## Related

- `../architecture/navigation.md`
- `../architecture/modules.md`
