//
//  ArtifactSidebarView.swift
//  FolderSizeVisualizer
//
//  Tool-based sidebar for developer artifact navigation
//

import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

struct ArtifactSidebarView: View {
    @Bindable var viewModel: ArtifactScanViewModel
    @Binding var isDeveloperModeEnabled: Bool
    @State private var isFullDiskAccessGranted: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Developer mode: ", isOn: $isDeveloperModeEnabled)
                .font(.headline)
            
            // Header
            Text("Developer Tools")
                .font(.headline)
            
            // Full Disk Access status
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if isFullDiskAccessGranted {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                        Text("Full Disk Access: Granted")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text("Full Disk Access: Not Granted")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                if !isFullDiskAccessGranted {
                    HStack(spacing: 8) {
                        Button {
                            FullDiskAccess.openSystemSettings()
                        } label: {
                            Label("Open Settings", systemImage: "gear")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            // Re-check current permission state
                            isFullDiskAccessGranted = FullDiskAccess.isGranted
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("After granting, you may need to restart the app for changes to take effect.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Scan button
            Button {
                viewModel.startScan()
            } label: {
                Label("Scan System", systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isScanning)

            Button {
                Task {
                    if await FileSystemHelper().requestAccessAndStoreBookmark(for: .llmCustomDirectories) != nil {
                        viewModel.rescanTool(.localLLMs)
                    }
                }
            } label: {
                Label("Add LLM Directory", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isScanning)

            Button {
                Task {
                    if await FileSystemHelper().requestAccessAndStoreBookmark(for: .venvProjectRoots) != nil {
                        viewModel.rescanTool(.venv)
                    }
                }
            } label: {
                Label("Add Venv Project Root", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isScanning)

            if viewModel.isScanning {
                scanningView()
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
                footerView()
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
        .task {
            // Initialize current status
            isFullDiskAccessGranted = FullDiskAccess.isGranted
        }
        #if canImport(AppKit)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Re-check when app becomes active again (e.g., after returning from Settings)
            isFullDiskAccessGranted = FullDiskAccess.isGranted
        }
        #endif
    }
    
    @ViewBuilder
    func scanningView() -> some View {
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
    
    @ViewBuilder
    func footerView() -> some View {
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
    ArtifactSidebarView(viewModel: ArtifactScanViewModel(), isDeveloperModeEnabled: .constant(true))
        .frame(width: 250)
}
