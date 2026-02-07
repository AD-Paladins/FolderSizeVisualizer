//
//  ArtifactContentView.swift
//  FolderSizeVisualizer
//
//  Main content view for artifact-based workflow
//

import SwiftUI

struct ArtifactContentView: View {
    @State private var viewModel = ArtifactScanViewModel()
    
    var body: some View {
        NavigationSplitView {
            ArtifactSidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
        } content: {
            if let selectedTool = viewModel.selectedTool {
                ToolDetailView(viewModel: viewModel, tool: selectedTool)
            } else {
                DashboardView(viewModel: viewModel)
            }
        } detail: {
            if let artifact = viewModel.selectedArtifact {
                ArtifactDetailView(artifact: artifact)
            } else if viewModel.selectedTool != nil {
                ContentUnavailableView(
                    "Select an Artifact",
                    systemImage: "square.stack.3d.up",
                    description: Text("Choose an artifact from the list to view detailed information")
                )
            } else {
                ContentUnavailableView(
                    "Welcome to Developer Disk Analyzer",
                    systemImage: "hammer.fill",
                    description: Text("Scan your system to analyze developer tool disk usage")
                )
            }
        }
    }
}

// MARK: - Artifact Detail View

struct ArtifactDetailView: View {
    let artifact: DeveloperArtifact
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: artifact.toolName.systemImage)
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(artifact.artifactType)
                                .font(.title)
                                .bold()
                            
                            Text(artifact.toolName.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Risk badge
                        HStack(spacing: 6) {
                            Image(systemName: artifact.riskLevel.systemImage)
                            Text(artifact.riskLevel.displayName)
                                .bold()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(riskColor(for: artifact.riskLevel).opacity(0.2))
                        .foregroundStyle(riskColor(for: artifact.riskLevel))
                        .clipShape(Capsule())
                    }
                }
                .padding()
                
                Divider()
                
                // Details
                VStack(alignment: .leading, spacing: 20) {
                    
                    // What is this?
                    DetailSection(title: "What is this?", icon: "info.circle") {
                        Text(artifact.explanationText)
                            .font(.body)
                    }
                    
                    // Size information
                    DetailSection(title: "Size", icon: "externaldrive") {
                        HStack {
                            Text(artifact.formattedSize)
                                .font(.title2)
                                .bold()
                            Spacer()
                        }
                    }
                    
                    // Rebuild cost
                    DetailSection(title: "Rebuild Cost", icon: "clock") {
                        Text(artifact.rebuildCostEstimate)
                            .font(.body)
                    }
                    
                    // Last used
                    if artifact.lastUsedDate != nil {
                        DetailSection(title: "Last Used", icon: "calendar") {
                            Text(artifact.lastUsedDescription)
                                .font(.body)
                        }
                    }
                    
                    // Safety status
                    DetailSection(title: "Safety Status", icon: "shield") {
                        HStack {
                            Image(systemName: artifact.safeToDelete ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(artifact.safeToDelete ? .green : .red)
                            
                            Text(artifact.safeToDelete ? "Safe to delete" : "Requires manual review")
                                .font(.body)
                            
                            Spacer()
                        }
                    }
                    
                    // Underlying paths
                    DetailSection(title: "Locations", icon: "folder") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(artifact.underlyingPaths, id: \.self) { path in
                                HStack {
                                    Text(path.path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                    
                                    Spacer()
                                    
                                    Button {
                                        NSWorkspace.shared.selectFile(path.path, inFileViewerRootedAtPath: "")
                                    } label: {
                                        Image(systemName: "arrow.right.circle")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Artifact Details")
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

// MARK: - Detail Section Component

struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            
            content
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    ArtifactContentView()
}
