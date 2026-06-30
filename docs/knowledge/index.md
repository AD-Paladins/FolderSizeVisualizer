# Repository Knowledge Index

> Vendor-neutral. Works with Claude, Cursor, OpenCode, Aider, Gemini CLI, etc.
> Read this file first. Then load only what's relevant to your task.

## Project

| | |
|---|---|
| Platform | macOS 15+ |
| Languages | Swift 6, SwiftUI 5 |
| Architecture | MVVM + Actor Services, pure SwiftUI |
| SDD | Active |

---

## World 1 — Project Knowledge (facts)

### Architecture

| Document | Path | Status |
|---|---|---|
| Overview | `architecture/overview.md` | ✅ |
| Navigation patterns | `architecture/navigation.md` | ✅ |
| SwiftUI ↔ AppKit bridge | `architecture/swiftui-uikit-bridge.md` | ✅ |
| Module breakdown | `architecture/modules.md` | ✅ |

### Standards

| Document | Path | Status |
|---|---|---|
| Swift | `standards/swift.md` | ✅ |
| SwiftUI | `standards/swiftui.md` | ✅ |
| AppKit (bridge) | `architecture/swiftui-uikit-bridge.md` | ✅ |
| Testing | `standards/testing.md` | ✅ |
| Accessibility | `standards/accessibility.md` | ⚠️ reflects limited current state |

> UIKit standards (`uikit-legacy.md`) are not applicable — this is a macOS app.

### Architecture Decisions (ADRs)

| Document | Path | Status |
|---|---|---|
| ADR index | `decisions/README.md` | ✅ |

_Add new ADRs here as they are created._

### Specs

| Feature | Spec | Design | Tasks | Tests | Dependencies |
|---|---|---|---|---|---|
| Navigation Bridge | `specs/navigation-bridge/SPEC.md` | N/A | N/A | N/A | N/A |

> Navigation bridge spec is N/A — this is a pure SwiftUI macOS project with no UIKit target.

_Add new specs here as they are created._

### Workflows

| Document | Path | Status |
|---|---|---|
| Spec-Driven Development | `workflows/sdd.md` | ✅ |
| Feature workflow | `workflows/feature.md` | ⚠️ references /sdd-new (not available in OpenCode) |
| Bugfix workflow | `workflows/bugfix.md` | ⚠️ references bridge specialist (AppKit, not UIKit) |

### Patterns

| Document | Path | Status |
|---|---|---|
| SwiftUI view | `patterns/swiftui-view.md` | ⚠️ uses @StateObject (app uses @Observable) |
| Coordinator pattern | `patterns/coordinator.md` | N/A — app uses state-driven navigation |

---

## World 2 — Agent Behavior (reasoning modes)

| Agent | Path | Use when |
|---|---|---|
| Planner | `agents/planner.md` | Starting a new feature or spec |
| Architect | `agents/architect.md` | Designing a module, making a pattern decision |
| Implementer | `agents/implementer.md` | Writing or extending Swift / SwiftUI / AppKit code |
| Reviewer | `agents/reviewer.md` | Reviewing PRs, auditing code quality |
| Tester | `agents/tester.md` | Writing unit or integration tests |
| Debugger | `agents/debugger.md` | Diagnosing crashes, layout issues |
| Bridge Specialist | `agents/bridge-specialist.md` | Any SwiftUI ↔ AppKit interaction |

---

## Status legend

| Symbol | Meaning |
|---|---|
| ✅ | Written and current |
| 🔲 stub | Referenced but not yet written — create before using |
| ⚠️ | Exists but needs update |
| N/A | Not applicable to this project |
