//
//  ArtifactContentView.swift
//  FolderSizeVisualizer
//
//  Main content view for artifact-based workflow
//

import SwiftUI

struct ArtifactContentView: View {
    @State private var viewModel = ArtifactScanViewModel()
    @Binding var isDeveloperModeEnabled: Bool
    
    var body: some View {
        NavigationSplitView {
            ArtifactSidebarView(viewModel: viewModel, isDeveloperModeEnabled: $isDeveloperModeEnabled)
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
        } content: {
            if let selectedTool = viewModel.selectedTool {
                ToolDetailView(viewModel: viewModel, tool: selectedTool)
                    .navigationSplitViewColumnWidth(min: 450, ideal: 480, max: 620)
            } else {
                // View visible only if there are no tools to be shown
                DashboardView(viewModel: viewModel)
                    .navigationSplitViewColumnWidth(min: 450, ideal: 480, max: 620)
            }
        } detail: {
            if let artifact = viewModel.selectedArtifact {
                ArtifactDetailView(artifact: artifact)
                    .navigationSplitViewColumnWidth(min: 450, ideal: 480, max: 620)
            } else if viewModel.selectedTool != nil {
                ContentUnavailableView(
                    "Select an Artifact",
                    systemImage: "square.stack.3d.up",
                    description: Text("Choose an artifact from the list to view detailed information")
                )
            } else {
                ContentUnavailableView(
                    "Welcome to Folder Size Visualizer",
                    systemImage: "hammer.fill",
                    description: Text("Scan your system to analyze developer tool disk usage")
                )
            }
        }
    }
}

#Preview {
    ArtifactContentView(isDeveloperModeEnabled: .constant(true))
}

