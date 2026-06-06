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

extension String {
    func markdownToAttributed() -> AttributedString {
        do {
            return try AttributedString(markdown: self)
        } catch {
            return AttributedString(self)
        }
    }
}

struct MarkdownText: View {
    let markdownString: String
    let lineLimit: Int
    init(markdownString: String,lineLimit: Int = 0) {
        self.markdownString = markdownString
        self.lineLimit = lineLimit
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(splitString, id: \.self) { line in
                Text(line.markdownToAttributed())
            }
        }
    }
    
    var splitString: [String] {
        let array = markdownString.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let positiveLineLimit = abs(lineLimit)
        if positiveLineLimit != 0, array.count > positiveLineLimit {
            var truncated = Array(array.prefix(positiveLineLimit))
            truncated[positiveLineLimit - 1] += " ..." // Append ellipsis to last line
            return truncated
        }
        return array
    }
}
// MARK: - Artifact Detail View

struct ArtifactDetailView: View {
    let artifact: DeveloperArtifact

    @State private var backupExists: Bool?

    private var isVenv: Bool { artifact.installedPackages != nil }

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
                        MarkdownText(markdownString: artifact.explanationText)
                    }

                    // Installed Packages (venv-specific)
                    if let packages = artifact.installedPackages, !packages.isEmpty {
                        DetailSection(
                            title: "Packages (\(packages.count))",
                            icon: "shippingbox"
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Spacer()
                                    Button("Copy List") {
                                        copyToClipboard(packages.joined(separator: "\n"))
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }

                                if packages.count <= 15 {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(packages, id: \.self) { pkg in
                                            HStack(spacing: 8) {
                                                Image(systemName: "circle.fill")
                                                    .font(.system(size: 5))
                                                    .foregroundStyle(.secondary)
                                                Text(pkg)
                                                    .font(.caption)
                                                    .foregroundStyle(.primary)
                                            }
                                        }
                                    }
                                } else {
                                    ScrollView(.vertical) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            ForEach(packages, id: \.self) { pkg in
                                                HStack(spacing: 8) {
                                                    Image(systemName: "circle.fill")
                                                        .font(.system(size: 5))
                                                        .foregroundStyle(.secondary)
                                                    Text(pkg)
                                                        .font(.caption)
                                                        .foregroundStyle(.primary)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxHeight: 200)
                                }
                            }
                        }
                    }

                    // Backup section (venv-specific)
                    if isVenv, let venvPath = artifact.underlyingPaths.first {
                        DetailSection(title: "Backup", icon: "externaldrive.badge.checkmark") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    if let exists = backupExists {
                                        if exists {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text("Backup saved")
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.orange)
                                            Text("No backup — deletion requires one")
                                                .foregroundStyle(.secondary)
                                        }
                                    } else {
                                        ProgressView()
                                            .controlSize(.small)
                                        Text("Checking backup...")
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }

                                HStack(spacing: 12) {
                                    Button {
                                        generateBackup(for: artifact, venvPath: venvPath)
                                    } label: {
                                        Label("Generate .md Backup", systemImage: "doc.badge.plus")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(backupExists == true)

                                    if let exists = backupExists, exists {
                                        Button {
                                            NSWorkspace.shared.selectFile(backupURL(for: venvPath).path, inFileViewerRootedAtPath: "")
                                        } label: {
                                            Image(systemName: "arrow.right.circle")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
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
        .task { await refreshBackupState() }
    }

    private func refreshBackupState() async {
        guard isVenv, let venvPath = artifact.underlyingPaths.first else { return }
        backupExists = FileManager.default.fileExists(atPath: backupURL(for: venvPath).path)
    }

    private func backupURL(for venvPath: URL) -> URL {
        URL(fileURLWithPath: venvPath.path + ".backup.md")
    }

    private func generateBackup(for artifact: DeveloperArtifact, venvPath: URL) {
        let url = backupURL(for: venvPath)
        let date = ISO8601DateFormatter().string(from: Date())

        let pkgSection: String
        if let pkgs = artifact.installedPackages, !pkgs.isEmpty {
            pkgSection = pkgs.map { "- \($0)" }.joined(separator: "\n")
        } else {
            pkgSection = "_No third-party packages detected_"
        }

        let content = """
        # Venv Backup — \(venvPath.lastPathComponent)

        **Generated:** \(date)
        **Project:** \(venvPath.deletingLastPathComponent().lastPathComponent)
        **Path:** \(venvPath.path)
        **Size:** \(ByteCountFormatter.string(fromByteCount: artifact.sizeBytes, countStyle: .file))

        ## Metadata

        \(artifact.explanationText)

        ## Installed Packages

        \(pkgSection)

        ## Recreate

        \(artifact.rebuildCostEstimate)
        """

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            backupExists = true
        } catch {
            print("Failed to write backup: \(error)")
        }
    }

    private func copyToClipboard(_ text: String) {
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    private func riskColor(for level: ArtifactRiskLevel) -> Color {
        switch level {
        case .safe: return .green
        case .slowRebuild: return .orange
        case .unsafe: return .red
        case .unknown: return .gray
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
    ArtifactContentView(isDeveloperModeEnabled: .constant(true))
}

