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
    
    init(viewModel: ScanViewModel = ScanViewModel(), selectedFolder: FolderEntry.ID? = nil, navigationStack: [URL]) {
        self.viewModel = viewModel
        self.selectedFolder = selectedFolder
        self.navigationStack = navigationStack
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .safeAreaInset(edge: .bottom) {
                    if viewModel.rootURL != nil {
                        VStack {
                            VStack(alignment: .leading) {
                                Text(viewModel.rootURL?.lastPathComponent ?? "N/A")
                                Text(ByteCountFormatter.string(
                                    fromByteCount: viewModel.totalSize,
                                    countStyle: .file
                                ))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            
                            Button(action: {
                                navigationStack.removeAll()
                                viewModel.resetAll()
                            }) {
                                Label("Start Over", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding([.bottom, .horizontal])
                            .padding(.top, 8)
                        }
                    }
                }
        } content: {
            ResultsListView(
                folderName: currentFolderName,
                folders: viewModel.folders,
                totalSize: viewModel.totalSize,
                selectedFolderID: $selectedFolder,
                onNavigateBack: onNavigateBack,
                onScanFolder: scanFolder
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
    ContentView(viewModel: ScanViewModel(), navigationStack: [])
}
