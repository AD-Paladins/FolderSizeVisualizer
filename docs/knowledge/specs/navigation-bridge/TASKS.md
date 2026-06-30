# Tasks: Navigation Bridge

> Resolve all open questions in `DESIGN.md` before starting implementation.

---

## Order

Tasks must be completed in this order — each step depends on the previous.

- [ ] 1. Resolve open questions in `DESIGN.md` and get arch sign-off
- [ ] 2. Define `Destination` enum with initial cases
- [ ] 3. Define `NavigationIntent` and `PresentationStyle`
- [ ] 4. Define `AppCoordinating` protocol
- [ ] 5. Implement `AppCoordinator` (UIKit side)
- [ ] 6. Add `CoordinatorKey` environment key
- [ ] 7. Wire coordinator into scene/root entry point
- [ ] 8. Migrate first SwiftUI→UIKit crossing to use the new bridge
- [ ] 9. Migrate first UIKit→SwiftUI crossing to use the new bridge
- [ ] 10. Remove all ad-hoc bridge code replaced by the above
- [ ] 11. Write tests (hand off to Tester agent)
- [ ] 12. Update `SPEC.md` status to `Accepted`
- [ ] 13. Update `../../index.md` — mark spec ✅

---

## Agent Assignments

| Tasks | Agent |
|---|---|
| 1 | Architect |
| 2–7 | Implementer + Bridge Specialist |
| 8–10 | Bridge Specialist |
| 11 | Tester |
| 12–13 | Planner or any agent closing the spec |
