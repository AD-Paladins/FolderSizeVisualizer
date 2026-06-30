# Example: SwiftUI View (ArtifactCard pattern)

A reference showing how views are structured in this project.

## ViewModel-Driven View

```swift
import SwiftUI

struct ToolDetailView: View {
    @Bindable var viewModel: ArtifactScanViewModel
    let tool: DeveloperTool

    var body: some View {
        List(artifacts) { artifact in
            ArtifactCard(artifact: artifact)
                .onTapGesture {
                    viewModel.selectedArtifact = artifact
                }
        }
        .navigationTitle(tool.displayName)
    }

    private var artifacts: [DeveloperArtifact] {
        viewModel.summaries.first { $0.tool == tool }?.artifacts ?? []
    }
}

#Preview {
    ToolDetailView(
        viewModel: {
            let vm = ArtifactScanViewModel()
            // populate with mock data
            return vm
        }(),
        tool: .xcode
    )
}
```

## Component Extraction Pattern

```swift
struct ArtifactCard: View {
    let artifact: DeveloperArtifact

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(artifact.artifactType)
                    .font(.headline)
                Text(artifact.explanationText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            RiskBadge(riskLevel: artifact.riskLevel)
            Text(artifact.sizeBytes.formatted(.byteCount(style: .file)))
                .font(.subheadline)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}
```

## Key Conventions

- Views use `@Bindable var viewModel` (not `@StateObject`)
- Components extracted as `private struct` or file-internal struct
- `body` delegates to sub-views via computed properties
- Every view has at least one `#Preview` with mock data
- Navigation is selection-driven (no `NavigationLink` — views set ViewModel state)
- No `AnyView` — use `@ViewBuilder` for conditional content

## Related

- `../standards/swiftui.md`
- `../standards/swift.md`
