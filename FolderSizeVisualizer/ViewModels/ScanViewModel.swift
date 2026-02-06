//
//  ScanViewModel.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/4/26.
//

import SwiftUI

@Observable
@MainActor
final class ScanViewModel {

    var folders: [FolderEntry] = []
    var isScanning = false
    var progress: Double = 0
    var isFromCache = false
    var currentScannedItem: String = ""

    var rootURL: URL?
    var maxResults: Int = 50
    var skipHiddenFiles: Bool = true

    var totalSize: Int64 {
        folders.reduce(0) { $0 + $1.size }
    }

    private let scanner = FolderScanner()
    private var scanTask: Task<Void, Never>?

    func startScan(url: URL) {
        cancelScan()

        rootURL = url
        isScanning = true
        progress = 0
        folders = []
        isFromCache = false
        currentScannedItem = ""

        scanTask = Task {
            let progressHandler: @Sendable (Double, String) async -> Void = { [weak self] value, itemName in
                Task { @MainActor in 
                    self?.progress = value
                    self?.currentScannedItem = itemName
                }
            }

            do {
                let result = try await scanner.scan(
                    root: url,
                    progress: progressHandler
                )

                folders = Array(result.folders.prefix(maxResults))
                
                // Check if result came from cache
                let cachedResult = await scanner.getCachedResult(for: url)
                isFromCache = (cachedResult?.folders == result.folders)
            } catch {
                folders = []
            }

            isScanning = false
        }
    }
    
    /// Refresh scan for a URL (clears cache for that URL and its subcaches)
    func refreshScan(url: URL) {
        Task {
            await scanner.refreshScan(for: url)
            startScan(url: url)
        }
    }
    
    /// Reset all - clear cache and reset to initial state
    func resetAll() {
        Task {
            await scanner.clearCache()
            cancelScan()
            folders = []
            rootURL = nil
            progress = 0
            isFromCache = false
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }
}