# 

This directory is the project's persistent memory. It exists so any agent (Claude, OpenCode, Cursor, etc.) can reconstruct context without re-reading the entire codebase.

## Structure

| Directory | Purpose |
|---|---|
| `architecture/` | How the app is built — patterns, navigation, modules |
| `standards/` | Language & framework conventions |
| `decisions/` | Architecture Decision Records |
| `specs/` | Feature specifications (SDD workflow) |
| `workflows/` | Development workflows (SDD, feature, bugfix) |
| `patterns/` | Reference implementations of common patterns |
| `agents/` | Agent behavior instructions per role |

## How to use

1. Read `index.md` first — it maps everything
2. Load only what's relevant to your task
3. Never read the entire tree

## Statuses

- ✅ Written and reflects current codebase
- 🔲 stub — referenced but not yet written
- ⚠️  Exists but needs update
- N/A — not applicable to this project
