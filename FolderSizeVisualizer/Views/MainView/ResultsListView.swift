//
//  ResultsListView.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/4/26.
//

import SwiftUI

struct ResultsListView: View {
    let folderName: String
    let folders: [FolderEntry]
    let totalSize: Int64
    @Binding var selectedFolderID: FolderEntry.ID?
    let onNavigateBack: (() -> Void)?
    let onScanFolder: ((URL) -> Void)?
    
    init(
        folderName: String,
        folders: [FolderEntry],
        totalSize: Int64,
        selectedFolderID: Binding<FolderEntry.ID?>,
        onNavigateBack: (() -> Void)? = nil,
        onScanFolder: ((URL) -> Void)? = nil
    ) {
        self.folderName = folderName
        self.folders = folders
        self.totalSize = totalSize
        self._selectedFolderID = selectedFolderID
        self.onNavigateBack = onNavigateBack
        self.onScanFolder = onScanFolder
    }

    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb navigation bar - only show if we can navigate back
            if let navigateBack = onNavigateBack {
                HStack {
                    Button {
                        navigateBack()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.regularMaterial)
            }
            
            List(folders, selection: $selectedFolderID) { folder in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(folder.name)
                            .font(.body)

                        Spacer()

                        Text(ByteCountFormatter.string(
                            fromByteCount: folder.size,
                            countStyle: .file
                        ))
                        .foregroundStyle(.secondary)
                    }

                    ProgressView(value: ratio(of: folder))
                        .progressViewStyle(.linear)
                }
                .padding(.vertical, 4)
                .onTapGesture(count: 2) {
                    onScanFolder?(folder.url)
                }
            }
        }
        .navigationTitle(folderNameString)
    }

    private func ratio(of folder: FolderEntry) -> Double {
        guard totalSize > 0 else { return 0 }
        return Double(folder.size) / Double(totalSize)
    }
    
    private var folderNameString: String {
        folderName.isEmpty
        ? "Scan a folder to get Results"
        : "Scan Results for \"\(folderName)\""
    }
}

#Preview {
    // Sample data for preview
    let sampleFolders: [FolderEntry] = [
        FolderEntry(url: URL(string: "~/Documents")!, size: 1_024_000),   // ~1 MB
        FolderEntry(url: URL(string: "~/Downloads")!, size: 52_428_800), // ~50 MB
        FolderEntry(url: URL(string: "~/Movies")!, size: 314_572_800), // ~300 MB
        FolderEntry(url: URL(string: "~/Pictures")!, size: 610_612_736)  // ~1.5 GB
    ]
    let sampleTotal = sampleFolders.reduce(0) { $0 + $1.size }

    NavigationSplitView {
        Text("Sidebar")
    } content: {
        ResultsListView(
            folderName: "~/",
            folders: sampleFolders,
            totalSize: sampleTotal,
            selectedFolderID: .constant(nil),
            onNavigateBack: nil
        )
    } detail: {
        Text("Details")
    }
}
