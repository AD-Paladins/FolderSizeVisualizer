//
//  ToolDetailView.swift
//  FolderSizeVisualizer
//
//  Detailed view showing all artifacts for a specific tool
//

import SwiftUI

struct ToolDetailView: View {
    @Bindable var viewModel: ArtifactScanViewModel
    let tool: DeveloperTool
    
    @State private var showDeleteConfirmation = false
    @State private var artifactToDelete: DeveloperArtifact?
    @State private var showBatchDeleteConfirmation = false
    
    @State private var intelligenceAvailability: ToolIntelligenceService.Availability = .unavailable("Checking…")
    @State private var isAnalyzingWithAI = false
    @State private var analysisResult: ToolIntelligenceResult?
    @State private var analysisError: String?
    @State private var cachedAIResults: [DeveloperTool: ToolIntelligenceResult] = [:]
    @State private var cachedAIErrors: [DeveloperTool: String] = [:]
    
    // Add a property to inject the intelligence provider
    @State private var intelligenceProvider: ToolIntelligenceProvider = ToolIntelligenceService()
    
    @State var docLinks: [DocLink] = []
    
    private func riskColor(for level: ArtifactRiskLevel) -> Color {
        switch level {
        case .safe: return .green
        case .slowRebuild: return .orange
        case .unsafe: return .red
        case .unknown: return .gray
        }
    }
    
    var summary: ToolArtifactSummary? {
        viewModel.toolSummaries.first { $0.tool == tool }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Tool header
                if let summary = summary {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            Image(systemName: tool.systemImage)
                                .font(.system(size: 48))
                                .foregroundStyle(.white)
                                .frame(width: 80, height: 80)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(tool.displayName)
                                    .font(.largeTitle)
                                    .bold()
                                
                                HStack(spacing: 16) {
                                    Label(summary.formattedTotalSize, systemImage: "externaldrive")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                    
                                    Label("\(summary.totalArtifacts) artifacts", systemImage: "square.stack.3d.up")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    
                    // Deletion responsibility banner
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("toolDetailView.warning.banner")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                    
                    // Apple Intelligence analysis
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Apple Intelligence Analysis", systemImage: "sparkles")
                            .font(.headline)

                        // Availability status
                        HStack(spacing: 8) {
                            switch intelligenceAvailability {
                            case .available:
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                                Text("Model available on this device")
                                    .foregroundStyle(.secondary)
                            case .unavailable(let reason):
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                                Text(reason)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .font(.caption)

                        // Controls / progress
                        if isAnalyzingWithAI {
                            HStack {
                                ProgressView()
                                Text("Analyzing…")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        } else {
                            Button {
                                guard case .available = intelligenceAvailability else { return }
                                analysisError = nil
                                analysisResult = nil
                                isAnalyzingWithAI = true
                                Task { @MainActor in
                                    do {
                                        let result = try await intelligenceProvider.analyze(tool: tool, summary: summary)
                                        self.analysisResult = result
                                        self.cachedAIResults[self.tool] = result
                                        self.cachedAIErrors[self.tool] = ""
                                    } catch {
                                        self.analysisError = error.localizedDescription
                                        self.cachedAIErrors[self.tool] = error.localizedDescription
                                        self.cachedAIResults[self.tool] = nil
                                    }
                                    self.isAnalyzingWithAI = false
                                }
                            } label: {
                                Label("Analyze with Apple Intelligence", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled({
                                if case .available = intelligenceAvailability { return false }
                                return true
                            }())
                        }

                        if analysisResult == nil && analysisError == nil {
                            Text("No analysis yet for \(tool.displayName).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Result / error
                        if let result = analysisResult {
                            AIResultView(result: result)
                        } else if let err = analysisError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Artifacts list
                    VStack(spacing: 12) {
                        ForEach(summary.artifacts) { artifact in
                            ArtifactCard(
                                artifact: artifact,
                                onDelete: {
                                    artifactToDelete = artifact
                                    showDeleteConfirmation = true
                                },
                                onSelect: {
                                    viewModel.selectArtifact(artifact)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                } else {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "magnifyingglass",
                        description: Text("Scan the system to see artifacts for \(tool.displayName)")
                    )
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(tool.displayName)
        .confirmationDialog(
            "Delete Artifact",
            isPresented: $showDeleteConfirmation,
            presenting: artifactToDelete
        ) { artifact in
            Button("Delete", role: .destructive) {
                viewModel.deleteArtifact(artifact)
            }
            Button("Cancel", role: .cancel) {}
        } message: { artifact in
            VStack(alignment: .leading, spacing: 8) {
                Text("Are you sure you want to delete this artifact?")
                Text("\n\(artifact.artifactType): \(artifact.formattedSize)")
                Text("\n⚠️ \(artifact.riskLevel.displayName): \(artifact.explanationText)")
            }
        }
        .confirmationDialog(
            "Clean Safe Artifacts",
            isPresented: $showBatchDeleteConfirmation
        ) {
            Button("Delete All Safe Artifacts", role: .destructive) {
                viewModel.deleteSafeArtifacts(for: tool)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let summary = summary {
                Text("Delete \(summary.safeToDeleteCount) safe artifact(s) and reclaim \(summary.formattedSafeToDeleteSize)?")
            }
        }
        .task(id: tool) {
            intelligenceAvailability = await intelligenceProvider.availability()
            analysisResult = cachedAIResults[tool]
            analysisError = cachedAIErrors[tool]
            isAnalyzingWithAI = false
        }
    }
}

// MARK: - Artifact Card Component

struct ArtifactCard: View {
    let artifact: DeveloperArtifact
    let onDelete: () -> Void
    let onSelect: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var backupExists: Bool = false
    @State private var backupChecked: Bool = false
    
    private var isVenv: Bool { artifact.installedPackages != nil }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(artifact.artifactType)
                        .font(.headline)
                    
                    if let lastUsed = artifact.lastUsedDate {
                        Text("Last used \(lastUsed.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Risk badge
                HStack(spacing: 4) {
                    Image(systemName: artifact.riskLevel.systemImage)
                        .font(.caption)
                    Text(artifact.riskLevel.displayName)
                        .font(.caption)
                        .bold()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(riskColor(for: artifact.riskLevel).opacity(0.2))
                .foregroundStyle(riskColor(for: artifact.riskLevel))
                .clipShape(Capsule())
            }
            
            // Description
            MarkdownText(markdownString: artifact.explanationText, lineLimit: 3)
                .foregroundStyle(.secondary)
            
            // Size and rebuild cost
            HStack {
                Label(artifact.formattedSize, systemImage: "externaldrive")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(artifact.rebuildCostEstimate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Actions
            HStack(spacing: 12) {
                Button {
                    onSelect()
                } label: {
                    Label("Details", systemImage: "info.circle")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                if artifact.safeToDelete && isVenv && !backupExists {
                    VStack(spacing: 2) {
                        Text("Backup required")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("Open details to generate")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else if artifact.safeToDelete {
                    Button {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(artifact.riskLevel == .safe ? .green : .orange)
                } else {
                    Text("Manual Review Required")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            isHovered = hovering
        }
        .padding()
        .background(isHovered ? Color(NSColor.controlBackgroundColor).opacity(0.95) : Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.accentColor.opacity(0.6) : .clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .task {
            guard isVenv, let venvPath = artifact.underlyingPaths.first else { return }
            let backupURL = URL(fileURLWithPath: venvPath.path + ".backup.md")
            backupExists = FileManager.default.fileExists(atPath: backupURL.path)
            backupChecked = true
        }
    }
    
    private func riskColor(for level: ArtifactRiskLevel) -> Color {
        switch level {
        case .safe:
            return .green
        case .slowRebuild:
            return .orange
        case .unsafe:
            return .red
        case .unknown:
            return .gray
        }
    }
}

struct DocumentationLinkRow: View {
    let link: DocLink
    
    var body: some View {
        Button {
            if let url = URL(string: link.url) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: "safari.fill")
                    .foregroundColor(.blue)
                Text(link.title)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .buttonStyle(.link)
    }
}

struct AIResultView: View {
    let result: ToolIntelligenceResult
    
    private func riskColor(for level: ArtifactRiskLevel) -> Color {
        switch level {
        case .safe:
            return .green
        case .slowRebuild:
            return .orange
        case .unsafe:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Risk badge and suggested action
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: result.riskLevel.systemImage).font(.caption)
                    Text(result.riskLevel.displayName).font(.caption).bold()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(riskColor(for: result.riskLevel).opacity(0.2))
                .foregroundStyle(riskColor(for: result.riskLevel))
                .clipShape(Capsule())
                
                HStack(spacing: 4) {
                    Image(systemName: {
                        switch result.suggestedAction {
                        case .delete: return "trash"
                        case .keep: return "checkmark"
                        case .review: return "eye"
                        }
                    }()).font(.caption)
                    Text({
                        switch result.suggestedAction {
                        case .delete: return "Suggested: Delete"
                        case .keep: return "Suggested: Keep"
                        case .review: return "Suggested: Review"
                        }
                    }()).font(.caption).bold()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
                
                Spacer()
            }
            
            MarkdownText(markdownString: result.enhancedDescription, lineLimit: 5)
                .foregroundStyle(.secondary)
            
            if !result.reason.isEmpty {
                Text("Reason: \(result.reason)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("Experimental feature")
                .font(.caption)
                .foregroundStyle(.orange)
                .bold()
                .padding(.top, 24)
                .padding(.bottom, 0)
            
            ForEach(result.documentationLinks) { link in
                DocumentationLinkRow(link: link)
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
            }
            
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}






#Preview {
    NavigationStack {
        ToolDetailView(viewModel: ArtifactScanViewModel(), tool: .xcode)
    }
}

