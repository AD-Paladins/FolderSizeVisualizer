//
//  SidebarView.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/4/26.
//

import SwiftUI

struct SidebarView: View {

    @Bindable var viewModel: ScanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Scan")
                .font(.headline)

            Button {
                selectFolder()
            } label: {
                Label("Select Folder", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)

            if let url = viewModel.rootURL {
                Text(url.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Divider()

            Toggle("Skip hidden files", isOn: $viewModel.skipHiddenFiles)
            Toggle("Limit results", isOn: $viewModel.limitResults)

            Stepper(viewModel.limitResults ? "Top \(viewModel.maxResults)" : "All results",
                    value: $viewModel.maxResults,
                    in: 5...100,
                    step: 5)
            .disabled(!viewModel.limitResults)

            Spacer()

            if viewModel.isScanning {
                ProgressView(value: max(0.0, min(viewModel.progress, 1.0))) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scanning…")
                            .font(.caption)
                        Text(viewModel.currentScannedItem)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .progressViewStyle(.linear)

                Button("Cancel") {
                    viewModel.cancelScan()
                }
            }
        }
        .padding()
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.startScan(url: url)
        }
    }
}

#Preview {
    SidebarView(viewModel: ScanViewModel())
}

