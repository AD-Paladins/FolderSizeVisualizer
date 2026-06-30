# SPEC: Navigation Bridge

## Status: N/A

This spec was scaffolded from a template that assumes a SwiftUI + UIKit hybrid project. **This is a pure SwiftUI macOS application** — no UIKit bridge exists or is needed.

AppKit interaction (file dialogs, pasteboard, workspace) is handled directly within service and utility files, gated behind `#if canImport(AppKit)`. No bridge layer is required.

## If the Project Gains a UIKit Target

Revisit this spec. The design in `DESIGN.md` (coordinator + intent pattern) would be appropriate for an iOS/macOS hybrid target.
