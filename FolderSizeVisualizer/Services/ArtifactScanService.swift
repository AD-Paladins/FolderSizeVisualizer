//
//  ArtifactScanService.swift
//  FolderSizeVisualizer
//
//  Coordinates all artifact detectors and provides unified scanning API
//

import Foundation

actor ArtifactScanService {
    
    // MARK: - Scan Result
    
    struct ScanResult: Sendable {
        let toolSummaries: [ToolArtifactSummary]
        let totalSize: Int64
        let totalSafeToDelete: Int64
        let scanDate: Date
        
        var formattedTotalSize: String {
            ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        }
        
        var formattedSafeToDeleteSize: String {
            ByteCountFormatter.string(fromByteCount: totalSafeToDelete, countStyle: .file)
        }
    }
    
    // MARK: - Properties
    
    private var detectors: [any ArtifactDetector] = []
    
    private var cachedResult: ScanResult?
    private let fileHelper = FileSystemHelper()
    
    // MARK: - Initialization
    
    init() { }
    
    /// Lazily construct detectors on first use to avoid calling any main-actor isolated initializers from a synchronous context
    private func ensureDetectorsInitialized() async {
        if detectors.isEmpty {
            async let myartifacts: [ArtifactDetector] =  [
                XcodeArtifactDetector(),
                SimulatorArtifactDetector(),
                AndroidArtifactDetector(),
                NodeJSArtifactDetector(),
                DockerArtifactDetector(),
                HomebrewArtifactDetector(),
                PythonArtifactDetector(),
                RustArtifactDetector()
            ]
            
            await self.detectors = myartifacts
        }
    }
    
    // MARK: - Scanning
    
    /// Scan all installed developer tools
    /// - Parameter progress: Callback for reporting progress (0.0 to 1.0) and current tool name
    /// - Returns: Scan result with all detected artifacts grouped by tool
    func scanAll(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> ScanResult {
        await ensureDetectorsInitialized()
        
        var allToolSummaries: [ToolArtifactSummary] = []
        
        let totalDetectors = detectors.count
        
        for (index, detector) in detectors.enumerated() {
            let tool = detector.tool
            let toolName = await tool.displayName
            
            // Check if tool is installed
            let isInstalled = await detector.isToolInstalled()
            
            guard isInstalled else {
                // Skip if not installed
                let progressValue = Double(index + 1) / Double(totalDetectors)
                await progress(progressValue, "Skipping \(toolName) (not installed)")
                continue
            }
            
            await progress(Double(index) / Double(totalDetectors), "Scanning \(toolName)...")
            
            do {
                // Run detector with sub-progress
                let artifacts = try await detector.detect { subProgress, subMessage in
                    let baseProgress = Double(index) / Double(totalDetectors)
                    let detectorProgress = subProgress / Double(totalDetectors)
                    await progress(baseProgress + detectorProgress, "\(toolName): \(subMessage)")
                }
                
                if !artifacts.isEmpty {
                    let summary = await ToolArtifactSummary(tool: tool, artifacts: artifacts)
                    allToolSummaries.append(summary)
                }
            } catch {
                // Log error but continue with other detectors
                await progress(Double(index + 1) / Double(totalDetectors), "Error scanning \(toolName)")
            }
        }
        
        // Calculate totals
        let totalSize = allToolSummaries.reduce(0) { $0 + $1.totalSize }
        let totalSafeToDelete = allToolSummaries.reduce(0) { $0 + $1.safeToDeleteSize }
        
        let result = ScanResult(
            toolSummaries: allToolSummaries.sorted { $0.totalSize > $1.totalSize },
            totalSize: totalSize,
            totalSafeToDelete: totalSafeToDelete,
            scanDate: Date()
        )
        
        cachedResult = result
        await progress(1.0, "Scan completed")
        
        return result
    }
    
    /// Scan a specific tool
    /// - Parameters:
    ///   - tool: The tool to scan
    ///   - progress: Progress callback
    /// - Returns: Tool summary for the specified tool
    func scanTool(_ tool: DeveloperTool, progress: @Sendable @escaping (Double, String) async -> Void) async throws -> ToolArtifactSummary? {
        await ensureDetectorsInitialized()
        
        guard let detector = detectors.first(where: { $0.tool == tool }) else {
            return nil
        }
        
        let isInstalled = await detector.isToolInstalled()
        guard isInstalled else {
            await progress(1.0, "\(tool.displayName) is not installed")
            return nil
        }
        
        let artifacts = try await detector.detect(progress: progress)
        
        guard !artifacts.isEmpty else {
            return nil
        }
        
        return await ToolArtifactSummary(tool: tool, artifacts: artifacts)
    }
    
    // MARK: - Cache Management
    
    func getCachedResult() -> ScanResult? {
        cachedResult
    }
    
    func clearCache() {
        cachedResult = nil
    }
    
    // MARK: - Deletion Operations
    
    /// Delete an artifact safely
    /// - Parameter artifact: The artifact to delete
    /// - Returns: Success status and optional error message
    func deleteArtifact(_ artifact: DeveloperArtifact) async -> (success: Bool, error: String?) {
        guard artifact.safeToDelete else {
            return (false, "Artifact is marked as unsafe to delete")
        }
        
        do {
            for path in artifact.underlyingPaths {
                try await fileHelper.delete(at: path)
            }
            
            // Invalidate cache
            clearCache()
            
            return (true, nil)
        } catch {
            return (false, "Failed to delete: \(error.localizedDescription)")
        }
    }
    
    /// Delete multiple artifacts
    /// - Parameter artifacts: Array of artifacts to delete
    /// - Returns: Number of successfully deleted artifacts and array of errors
    func deleteArtifacts(_ artifacts: [DeveloperArtifact]) async -> (deletedCount: Int, errors: [String]) {
        var deletedCount = 0
        var errors: [String] = []
        
        for artifact in artifacts {
            let result = await deleteArtifact(artifact)
            if result.success {
                deletedCount += 1
            } else if let error = result.error {
                errors.append("\(artifact.artifactType): \(error)")
            }
        }
        
        return (deletedCount, errors)
    }
    
    /// Delete all safe artifacts for a specific tool
    /// - Parameter tool: The tool whose safe artifacts should be deleted
    /// - Returns: Deletion result
    func deleteSafeArtifacts(for tool: DeveloperTool) async -> (deletedCount: Int, reclaimedSize: Int64, errors: [String]) {
        guard let summary = cachedResult?.toolSummaries.first(where: { $0.tool == tool }) else {
            return (0, 0, ["No cached data for \(await tool.displayName)"])
        }
        
        let safeArtifacts = summary.artifacts.filter { $0.safeToDelete }
        let reclaimableSize = safeArtifacts.reduce(0) { $0 + $1.sizeBytes }
        
        let result = await deleteArtifacts(safeArtifacts)
        
        return (result.deletedCount, reclaimableSize, result.errors)
    }
}

