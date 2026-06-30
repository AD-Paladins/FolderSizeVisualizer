# Workflow: Spec-Driven Development (SDD)

## Overview

SDD structures every meaningful change into a repeatable lifecycle: explore → propose → spec → design → tasks → implement → verify → archive.

Not every change needs the full cycle. Small bug fixes may skip straight to implement + verify. Use judgment.

## Phases

### 1. Explore
Investigate the problem space. Read existing code, specs, and decisions. Capture findings. Decide whether to proceed.

**Output:** `../specs/<feature>/` or a decision to skip

### 2. Propose
Define the intent, scope, and approach. Get alignment before investing in detail.

**Output:** Proposal with success criteria

### 3. Spec
Write the detailed specification: requirements, scenarios, non-goals, acceptance criteria.

**Output:** `../specs/<feature>/SPEC.md`, `depends-on.md`

### 4. Design
Define the technical approach: types, protocols, data flow, interfaces. Resolve open questions.

If the change affects navigation structure or introduces new UI components, update [`../../ux-design/specifications.md`](../../ux-design/specifications.md) to reflect the new state.

**Output:** `../specs/<feature>/DESIGN.md`

### 5. Tasks
Break the change into ordered, assignable implementation tasks.

**Output:** `../specs/<feature>/TASKS.md`

### 6. Implement
Work through tasks top to bottom. Each task produces compilable, tested code.

### 7. Verify
Execute tests and prove the implementation matches the spec.

**Output:** Passing tests, verified acceptance criteria

### 8. Archive
Update `../index.md`, mark spec artifacts as accepted, clean up delta specs.

Before closing: confirm that [`../../ux-design/specifications.md`](../../ux-design/specifications.md) reflects any navigation or component changes introduced by this change.

**Output:** Updated index, closed spec

## Agent Roles per Phase

| Phase | Agent |
|---|---|
| Explore | Explore |
| Propose | Propose |
| Spec | Spec |
| Design | Architect |
| Tasks | Tasks |
| Implement | Implementer / Bridge Specialist |
| Verify | Verify |
| Archive | Archive |
