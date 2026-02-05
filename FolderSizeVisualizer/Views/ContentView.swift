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
    @State private var navigationStack: [URL] = []
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } content: {
            ResultsListView(
                folderName: currentFolderName,
                folders: viewModel.folders,
                totalSize: viewModel.totalSize,
                selectedFolderID: $selectedFolder,
                onNavigateBack: onNavigateBack
            )
        } detail: {
            if let selectedID = selectedFolder,
               let folder = viewModel.folders.first(where: { $0.id == selectedID }) {
                FolderDetailView(
                    folder: folder,
                    totalSize: viewModel.totalSize,
                    onScanFolder: scanFolder
                )
            } else {
                ContentUnavailableView(
                    "Select a Folder",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Choose a folder from the list to view detailed analysis")
                )
            }
        }
        .onChange(of: viewModel.rootURL) { oldValue, newValue in
            // Reset navigation when starting a new scan from sidebar
            if oldValue != newValue {
//                navigationStack = []
                selectedFolder = nil
            }
        }
    }
    
    private var onNavigateBack: (() -> Void)? {
        navigationStack.isEmpty ? nil : (navigateBack as () -> Void)
    }
    
    private var currentFolderName: String {
        if let current = viewModel.rootURL {
            return current.lastPathComponent.isEmpty ? current.path : current.lastPathComponent
        }
        return ""
    }
    
    // TODO: - Store parent scans to not do the job again when navigating back
    private func navigateBack() {
        guard let previousURL = navigationStack.popLast() else {
            return
        }
        // Clear selection and scan the previous folder
        selectedFolder = nil
        viewModel.startScan(url: previousURL)
    }
    
    private func scanFolder(_ url: URL) {
        // Add current folder to navigation stack
        if let currentRoot = viewModel.rootURL {
            navigationStack.append(currentRoot)
        }
        
        // Clear selection and scan the new folder
        selectedFolder = nil
        viewModel.startScan(url: url)
    }
}

#Preview {
    ContentView()
}
