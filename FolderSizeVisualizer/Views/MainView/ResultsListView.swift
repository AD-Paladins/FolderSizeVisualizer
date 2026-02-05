//
//  ResultsListView.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/4/26.
//

import SwiftUI

struct ResultsListView: View {
    let folders: [FolderEntry]
    let totalSize: Int64
    @Binding var selectedFolderID: FolderEntry.ID?

    var body: some View {
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
        }
        .navigationTitle("Scan Results")
    }

    private func ratio(of folder: FolderEntry) -> Double {
        guard totalSize > 0 else { return 0 }
        return Double(folder.size) / Double(totalSize)
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

    ResultsListView(
        folders: sampleFolders,
        totalSize: sampleTotal,
        selectedFolderID: .constant(nil)
    )
}
