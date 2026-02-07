//
//  ArtifactSidebarView.swift
//  FolderSizeVisualizer
//
//  Tool-based sidebar for developer artifact navigation
//

import SwiftUI

struct ArtifactSidebarView: View {
    @Bindable var viewModel: ArtifactScanViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Header
            Text("Developer Tools")
                .font(.headline)
            
            // Scan button
            Button {
                viewModel.startScan()
            } label: {
                Label("Scan System", systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isScanning)
            
            if viewModel.isScanning {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: viewModel.progress) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scanning...")
                                .font(.caption)
                            Text(viewModel.currentScanItem)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .progressViewStyle(.linear)
                    
                    Button("Cancel") {
                        viewModel.cancelScan()
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            Divider()
            
            // Tool list
            if !viewModel.toolSummaries.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.toolSummaries) { summary in
                            ToolSidebarRow(
                                summary: summary,
                                isSelected: viewModel.selectedTool == summary.tool
                            )
                            .onTapGesture {
                                viewModel.selectTool(summary.tool)
                            }
                        }
                    }
                }
            } else if viewModel.hasResults {
                Text("No artifacts found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Summary section
            if viewModel.hasResults {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Total Size")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(viewModel.formattedTotalSize)
                                .font(.caption)
                                .bold()
                        }
                        
                        HStack {
                            Text("Safe to Delete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(viewModel.formattedSafeToDeleteSize)
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.green)
                        }
                    }
                    
                    if let scanDate = viewModel.scanDate {
                        Text("Scanned \(scanDate.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
        .alert(
            "Deletion Result",
            isPresented: .init(
                get: { viewModel.lastDeletionResult != nil },
                set: { if !$0 { viewModel.clearDeletionResult() } }
            )
        ) {
            Button("OK") {
                viewModel.clearDeletionResult()
            }
        } message: {
            if let result = viewModel.lastDeletionResult {
                Text(result.message)
            }
        }
    }
}

// MARK: - Tool Sidebar Row

struct ToolSidebarRow: View {
    let summary: ToolArtifactSummary
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: summary.tool.systemImage)
                .font(.title3)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.tool.displayName)
                    .font(.body)
                    .foregroundStyle(isSelected ? .primary : .primary)
                
                HStack(spacing: 8) {
                    Text(summary.formattedTotalSize)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if summary.safeToDeleteCount > 0 {
                        Text("• \(summary.safeToDeleteCount) safe")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ArtifactSidebarView(viewModel: ArtifactScanViewModel())
        .frame(width: 250)
}
