# SwiftUI ↔ UIKit Bridge

## N/A — macOS Application

This project is a **macOS-only SwiftUI application**. UIKit is not used and no bridge is needed.

## AppKit Surface

AppKit is used in limited, well-defined areas. See `../architecture/overview.md` for the full list.

## If AppKit Bridge Work Is Needed

For any AppKit interaction (e.g. `NSOpenPanel`, `NSWorkspace`, `NSAlert`), follow these rules:

- Gate all AppKit imports behind `#if canImport(AppKit)`
- Keep AppKit code in `Utilities/` or the relevant service file
- Do not import AppKit in SwiftUI `View` files — extract into helper types
- Wrap AppKit callbacks into async APIs where possible (e.g. `NSOpenPanel` + `continuation`)
