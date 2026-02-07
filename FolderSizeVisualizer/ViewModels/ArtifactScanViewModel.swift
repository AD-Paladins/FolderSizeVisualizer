//
//  ArtifactScanViewModel.swift
//  FolderSizeVisualizer
//
//  ViewModel for artifact-based scanning workflow
//

import SwiftUI

@Observable
@MainActor
final class ArtifactScanViewModel {
    
    // MARK: - State
    
    var toolSummaries: [ToolArtifactSummary] = []
    var isScanning = false
    var progress: Double = 0
    var currentScanItem: String = ""
    var scanDate: Date?
    
    var totalSize: Int64 = 0
    var totalSafeToDelete: Int64 = 0
    
    var selectedTool: DeveloperTool?
    var selectedArtifact: DeveloperArtifact?
    
    // Deletion state
    var isDeletingArtifacts = false
    var deletionProgress: Double = 0
    var lastDeletionResult: DeletionResult?
    
    struct DeletionResult: Identifiable {
        let id = UUID()
        let success: Bool
        let deletedCount: Int
        let reclaimedSize: Int64
        let errors: [String]
        
        var message: String {
            if success && errors.isEmpty {
                let sizeStr = ByteCountFormatter.string(fromByteCount: reclaimedSize, countStyle: .file)
                return "Successfully deleted \(deletedCount) artifact(s), reclaimed \(sizeStr)"
            } else if deletedCount > 0 {
                let sizeStr = ByteCountFormatter.string(fromByteCount: reclaimedSize, countStyle: .file)
                return "Deleted \(deletedCount) artifact(s) (\(sizeStr)), but \(errors.count) error(s) occurred"
            } else {
                return "Failed to delete artifacts"
            }
        }
    }
    
    // MARK: - Service
    
    private let scanService = ArtifactScanService()
    private var scanTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedSafeToDeleteSize: String {
        ByteCountFormatter.string(fromByteCount: totalSafeToDelete, countStyle: .file)
    }
    
    var hasResults: Bool {
        !toolSummaries.isEmpty
    }
    
    var selectedToolSummary: ToolArtifactSummary? {
        guard let tool = selectedTool else { return nil }
        return toolSummaries.first { $0.tool == tool }
    }
    
    // MARK: - Scanning
    
    func startScan() {
        cancelScan()
        
        isScanning = true
        progress = 0
        toolSummaries = []
        currentScanItem = ""
        selectedTool = nil
        selectedArtifact = nil
        
        scanTask = Task { @MainActor in
            let progressHandler: @Sendable (Double, String) async -> Void = { [weak self] value, itemName in
                await MainActor.run {
                    self?.progress = value
                    self?.currentScanItem = itemName
                }
            }
            
            do {
                let result = try await scanService.scanAll(progress: progressHandler)
                
                print("✅ Scan completed: \(result.toolSummaries.count) tools found")
                for summary in result.toolSummaries {
                    print("  - \(summary.tool.displayName): \(summary.totalArtifacts) artifacts, \(summary.formattedTotalSize)")
                }
                
                self.toolSummaries = result.toolSummaries
                self.totalSize = result.totalSize
                self.totalSafeToDelete = result.totalSafeToDelete
                self.scanDate = result.scanDate
                
            } catch {
                print("❌ Scan error: \(error)")
                self.toolSummaries = []
            }
            
            self.isScanning = false
        }
    }
    
    func rescanTool(_ tool: DeveloperTool) {
        guard !isScanning else { return }
        
        isScanning = true
        progress = 0
        currentScanItem = "Rescanning \(tool.displayName)..."
        
        scanTask = Task { @MainActor in
            let progressHandler: @Sendable (Double, String) async -> Void = { [weak self] value, itemName in
                await MainActor.run {
                    self?.progress = value
                    self?.currentScanItem = itemName
                }
            }
            
            do {
                if let summary = try await scanService.scanTool(tool, progress: progressHandler) {
                    // Update or add the tool summary
                    if let index = self.toolSummaries.firstIndex(where: { $0.tool == tool }) {
                        self.toolSummaries[index] = summary
                    } else {
                        self.toolSummaries.append(summary)
                    }
                    
                    // Recalculate totals
                    self.totalSize = self.toolSummaries.reduce(0) { $0 + $1.totalSize }
                    self.totalSafeToDelete = self.toolSummaries.reduce(0) { $0 + $1.safeToDeleteSize }
                }
            } catch {
                print("Rescan error for \(tool.displayName): \(error)")
            }
            
            self.isScanning = false
        }
    }
    
    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }
    
    // MARK: - Deletion
    
    func deleteArtifact(_ artifact: DeveloperArtifact) {
        guard !isDeletingArtifacts else { return }
        
        isDeletingArtifacts = true
        deletionProgress = 0
        
        Task { @MainActor in
            let result = await scanService.deleteArtifact(artifact)
            
            if result.success {
                self.lastDeletionResult = DeletionResult(
                    success: true,
                    deletedCount: 1,
                    reclaimedSize: artifact.sizeBytes,
                    errors: []
                )
                
                // Rescan the tool
                self.rescanTool(artifact.toolName)
            } else {
                self.lastDeletionResult = DeletionResult(
                    success: false,
                    deletedCount: 0,
                    reclaimedSize: 0,
                    errors: [result.error ?? "Unknown error"]
                )
            }
            
            self.isDeletingArtifacts = false
        }
    }
    
    func deleteSafeArtifacts(for tool: DeveloperTool) {
        guard !isDeletingArtifacts else { return }
        
        isDeletingArtifacts = true
        deletionProgress = 0
        
        Task { @MainActor in
            let result = await scanService.deleteSafeArtifacts(for: tool)
            
            self.lastDeletionResult = DeletionResult(
                success: result.errors.isEmpty,
                deletedCount: result.deletedCount,
                reclaimedSize: result.reclaimedSize,
                errors: result.errors
            )
            
            self.isDeletingArtifacts = false
            
            // Rescan the tool
            if result.deletedCount > 0 {
                self.rescanTool(tool)
            }
        }
    }
    
    func clearDeletionResult() {
        lastDeletionResult = nil
    }
    
    // MARK: - Selection
    
    func selectTool(_ tool: DeveloperTool) {
        selectedTool = tool
        selectedArtifact = nil
    }
    
    func selectArtifact(_ artifact: DeveloperArtifact) {
        selectedArtifact = artifact
        selectedTool = artifact.toolName
    }
    
    func clearSelection() {
        selectedTool = nil
        selectedArtifact = nil
    }
}
