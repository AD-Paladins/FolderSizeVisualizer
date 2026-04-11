//
//  DashboardView.swift
//  FolderSizeVisualizer
//
//  Main dashboard showing tool footprints and quick actions
//

import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: ArtifactScanViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Developer Disk Usage")
                        .font(.largeTitle)
                        .bold()
                    
                    if viewModel.hasResults {
                        Text("Found \(viewModel.toolSummaries.count) tool(s) using \(viewModel.formattedTotalSize)")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Scan your system to analyze developer tool disk usage")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                if !viewModel.hasResults {
                    // Empty state
                    ContentUnavailableView(
                        "No Scan Results",
                        systemImage: "magnifyingglass",
                        description: Text("Click 'Scan System' in the sidebar to analyze your developer tools")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    // Tool cards grid
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
                    ], spacing: 16) {
                        ForEach(viewModel.toolSummaries) { summary in
                            ToolCard(
                                summary: summary,
                                isSelected: viewModel.selectedTool == summary.tool,
                                onSelect: {
                                    viewModel.selectTool(summary.tool)
                                },
                                onCleanSafe: {
                                    showCleanConfirmation(for: summary.tool)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Dashboard")
    }
    
    private func showCleanConfirmation(for tool: DeveloperTool) {
        // This will be handled by the parent view with proper confirmation dialogs
        viewModel.selectTool(tool)
    }
}

// MARK: - Tool Card

struct ToolCard: View {
    let summary: ToolArtifactSummary
    let isSelected: Bool
    let onSelect: () -> Void
    let onCleanSafe: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: summary.tool.systemImage)
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.tool.displayName)
                        .font(.title3)
                        .bold()
                    
                    Text("\(summary.totalArtifacts) artifact(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Stats
            VStack(spacing: 12) {
                HStack {
                    Label("Total Size", systemImage: "externaldrive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(summary.formattedTotalSize)
                        .font(.title3)
                        .bold()
                }
                
                if summary.safeToDeleteCount > 0 {
                    HStack {
                        Label("Safe to Delete", systemImage: "checkmark.shield")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Spacer()
                        Text(summary.formattedSafeToDeleteSize)
                            .font(.body)
                            .bold()
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // Actions
            HStack(spacing: 12) {
                Button {
                    onSelect()
                } label: {
                    Text("View Details")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                if summary.safeToDeleteCount > 0 {
                    Button {
                        onCleanSafe()
                    } label: {
                        Text("Clean Safe")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    NavigationStack {
        DashboardView(viewModel: ArtifactScanViewModel())
    }
}
