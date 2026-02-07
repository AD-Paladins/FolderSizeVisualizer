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
                        
                        // Quick actions
                        HStack(spacing: 12) {
                            if summary.safeToDeleteCount > 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Safe to Delete")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(summary.formattedSafeToDeleteSize)
                                        .font(.title2)
                                        .bold()
                                        .foregroundStyle(.green)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button {
                                    showBatchDeleteConfirmation = true
                                } label: {
                                    Label("Clean Safe Artifacts", systemImage: "trash")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            } else {
                                ContentUnavailableView(
                                    "No Safe Deletions Available",
                                    systemImage: "checkmark.shield",
                                    description: Text("All artifacts for \(tool.displayName) require manual review")
                                )
                            }
                        }
                    }
                    .padding()
                    
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
    }
}

// MARK: - Artifact Card Component

struct ArtifactCard: View {
    let artifact: DeveloperArtifact
    let onDelete: () -> Void
    let onSelect: () -> Void
    
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
            Text(artifact.explanationText)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
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
                
                if artifact.safeToDelete {
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
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

#Preview {
    NavigationStack {
        ToolDetailView(viewModel: ArtifactScanViewModel(), tool: .xcode)
    }
}
