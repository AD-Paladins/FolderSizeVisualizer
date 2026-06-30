# Workflow: New Feature

## When to Use

Any new screen, user-facing capability, or significant change to existing behavior.

---

## Steps

### 1. Start with `/sdd-new`

Run the `/sdd-new` command. It will:
- Ask for the feature name
- Scaffold the spec folder under `../specs/<feature-name>/`
- Add a stub entry to `../index.md`

### 2. Fill the spec (Planner agent)

Complete `SPEC.md`:
- Define the problem and goals clearly
- List explicit non-goals
- Fill `depends-on.md` with the documents this feature needs

### 3. Design (Architect agent)

Complete `DESIGN.md`:
- Define all new types and interfaces
- Draw the data flow
- Resolve open questions before moving on

### 4. Task breakdown (Planner agent)

Complete `TASKS.md` with ordered, assignable steps.

### 5. Implement (Implementer agent)

Work through `TASKS.md` top to bottom.  
If SwiftUI ↔ UIKit is involved, switch to Bridge Specialist agent.

### 6. Test (Tester agent)

Complete `TESTS.md` acceptance criteria.  
All criteria must pass before marking the feature done.

### 7. Review (Reviewer agent)

Code review against standards and spec alignment.

### 8. Close the spec

- Mark tasks ✅ in `TASKS.md`
- Update spec status to `Accepted` in `SPEC.md`
- Update `../index.md` entry to ✅

---

## Related

- `../workflows/sdd.md` — full SDD reference
- `../agents/planner.md`
