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

        scanTask = Task {
            let progressHandler: @Sendable (Double) -> Void = { [weak self] value in
                Task { @MainActor in self?.progress = value }
            }

            do {
                let result = try await scanner.scan(
                    root: url,
                    progress: progressHandler
                )

                folders = Array(result.folders.prefix(maxResults))
            } catch {
                folders = []
            }

            isScanning = false
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }
}

/*
 
 @Observable
 @MainActor
 final class ScanViewModel {

     var folders: [FolderEntry] = []
     var isScanning = false
     var progress: Double = 0

     private let scanner = FolderScanner()
     private var scanTask: Task<Void, Never>?

     func startScan(url: URL) {
         cancelScan()

         isScanning = true
         progress = 0
         folders = []

         scanTask = Task {
             // Make the progress callback @Sendable and hop to the main actor for UI updates
             let progressHandler: @Sendable (Double) -> Void = { [weak self] value in
                 Task { @MainActor in
                     self?.progress = value
                 }
             }
             do {
                 let result = try await scanner.scan(root: url, progress: progressHandler)

                 folders = Array(result.folders.prefix(50)) // safeguard
             } catch {
                 folders = []
             }

             isScanning = false
         }
     }

     func cancelScan() {
         scanTask?.cancel()
         scanTask = nil
         isScanning = false
     }
 }


 */
