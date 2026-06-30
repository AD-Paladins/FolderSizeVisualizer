# Example: Coordinator Pattern

## N/A — This Project

This app uses **state-driven navigation** with `NavigationSplitView`, not a coordinator pattern.

Navigation is driven by ViewModel state (`selectedTool`, `selectedArtifact`). Views read state; they do not emit intents to a coordinator.

If the project ever needs iOS support or multi-window navigation, revisit the coordinator pattern defined in `../specs/navigation-bridge/DESIGN.md`.
