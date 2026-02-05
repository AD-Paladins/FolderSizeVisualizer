//
//  ScanViewModel.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/4/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = ScanViewModel()
    @State private var selectedFolder: FolderEntry.ID?

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } content: {
            ResultsListView(
                folders: viewModel.folders,
                totalSize: viewModel.totalSize,
                selectedFolderID: $selectedFolder
            )
        } detail: {
            if let selectedID = selectedFolder,
               let folder = viewModel.folders.first(where: { $0.id == selectedID }) {
                FolderDetailView(
                    folder: folder,
                    totalSize: viewModel.totalSize
                )
            } else {
                ContentUnavailableView(
                    "Select a Folder",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Choose a folder from the list to view detailed analysis")
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
