# Workflow: Bug Fix

## When to Use

A confirmed bug with a clear reproduction case. Not for refactors or feature additions — those use the feature workflow.

---

## Steps

### 1. Reproduce and characterize

Before writing any code:
- Confirm the reproduction steps
- Identify which layer the bug lives in (SwiftUI view, view model, service, bridge, UIKit legacy)
- Check if an existing spec or ADR is relevant

### 2. Load context (Debugger agent)

Switch to the Debugger agent.  
Load only the documents relevant to the affected area — check `../index.md`.

### 3. Identify root cause

Do not fix symptoms. Find the root cause before writing a fix.  
If the root cause reveals a missing architectural decision, note it for an ADR.

### 4. Fix

Smallest possible change that fixes the root cause.  
Do not refactor adjacent code as part of a bug fix.

### 5. Verify

- Confirm the reproduction case no longer triggers the bug
- Check that existing tests still pass
- Add a regression test if none existed for this case

### 6. Document if needed

If the bug revealed a gap in `../`:
- Update the relevant standard or architecture doc
- Or open a stub for a missing document

---

## Bridge Bugs

If the bug is in the SwiftUI ↔ UIKit bridge, switch to the Bridge Specialist agent after step 2.

---

## Related

- `../agents/debugger.md`
- `../architecture/swiftui-uikit-bridge.md`
