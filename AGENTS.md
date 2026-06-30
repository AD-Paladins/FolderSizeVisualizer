# AGENTS.md

This file is a bootstrap. It tells you where to find knowledge — it does not contain knowledge itself.

---

## Step 1 — Read the index

```
docs/knowledge/index.md
```

This is the repository knowledge graph. It maps every document, spec, standard, decision, and agent behavior file. Read it before reading anything else.

---

## Step 2 — Determine your task

| Task type | Load first |
|---|---|
| New feature | `docs/knowledge/workflows/sdd.md`, then `docs/knowledge/agents/planner.md` |
| Writing code | `docs/knowledge/agents/implementer.md` |
| SwiftUI ↔ UIKit work | `docs/knowledge/agents/bridge-specialist.md` |
| Code review | `docs/knowledge/agents/reviewer.md` |
| Writing tests | `docs/knowledge/agents/tester.md` |
| Debugging | `docs/knowledge/agents/debugger.md` |
| Architecture decision | `docs/knowledge/agents/architect.md` |

---

## Step 3 — Load only what's relevant

A spec folder (e.g. `docs/knowledge/specs/<feature>/`) contains a `depends-on.md` listing exactly which documents to load for that feature. Read it before reading the spec itself. Do not read the entire `docs/knowledge/` tree.

---

## Step 4 — AI commands

If the user asks about setting up `/sdd-new` or AI command installation, see [`docs/scripts/ai-commands-setup.md`](docs/scripts/ai-commands-setup.md).

---

## Principle

Never read more than you need. Every document you load costs context. The index exists to prevent that cost.
