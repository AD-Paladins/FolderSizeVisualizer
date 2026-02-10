//
//  ArtifactScanService.swift
//  FolderSizeVisualizer
//
//  Coordinates all artifact detectors and provides unified scanning API
//

import Foundation

actor ArtifactScanService {
    
    struct PathConfig: Sendable {
        // Default known locations
        var derivedData: URL = URL(fileURLWithPath: "~/Library/Developer/Xcode/DerivedData").standardizedFileURL
        var archives: URL = URL(fileURLWithPath: "~/Library/Developer/Xcode/Archives").standardizedFileURL
        var simulatorRuntimesRoot: URL = URL(fileURLWithPath: "/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime").standardizedFileURL
        var assetsRoot: URL = URL(fileURLWithPath: "/System/Library/AssetsV2").standardizedFileURL

        // Per-tool override roots (if user wants custom locations)
        var overrides: [String: URL] = [:]

        func url(for key: String, default url: URL) -> URL {
            if let override = overrides[key] { return override }
            return url
        }
    }
    
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
    
    private var pathConfig = PathConfig()

    // MARK: - Path Overrides API

    enum ToolPathKey: String { case xcodeDerivedData, xcodeArchives, simulatorRuntimes, assetsRoot, android, node, docker, homebrew, python, rust }

    func setOverride(_ url: URL, for key: ToolPathKey) {
        pathConfig.overrides[key.rawValue] = url
        clearCache()
    }

    func clearOverride(for key: ToolPathKey) {
        pathConfig.overrides.removeValue(forKey: key.rawValue)
        clearCache()
    }

    func resolvedURL(for key: ToolPathKey) -> URL {
        switch key {
        case .xcodeDerivedData:
            return pathConfig.url(for: key.rawValue, default: pathConfig.derivedData)
        case .xcodeArchives:
            return pathConfig.url(for: key.rawValue, default: pathConfig.archives)
        case .simulatorRuntimes:
            return pathConfig.url(for: key.rawValue, default: pathConfig.simulatorRuntimesRoot)
        case .assetsRoot:
            return pathConfig.url(for: key.rawValue, default: pathConfig.assetsRoot)
        case .android, .node, .docker, .homebrew, .python, .rust:
            // For non-Xcode tools, provide the override only; callers decide sensible defaults
            return pathConfig.url(for: key.rawValue, default: FileManager.default.homeDirectoryForCurrentUser)
        }
    }

    // MARK: - Well-known paths (with existence checks)

    func derivedDataDirectory() -> URL? {
        let url = resolvedURL(for: .xcodeDerivedData)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func archivesDirectory() -> URL? {
        let url = resolvedURL(for: .xcodeArchives)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func simulatorRuntimesDirectory() -> URL? {
        let url = resolvedURL(for: .simulatorRuntimes)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func systemAssetsDirectory() -> URL? {
        let url = resolvedURL(for: .assetsRoot)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    private var cachedResult: ScanResult?
    private let fileHelper = FileSystemHelper()
    
    // MARK: - Initialization
    
    init() { }
    
    /// Lazily construct detectors on first use to avoid calling any main-actor isolated initializers from a synchronous context
    private func ensureDetectorsInitialized() async {
        if detectors.isEmpty {
            async let myartifacts: [any ArtifactDetector] =  [
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
            
            print("🔍 Checking \(toolName): \(isInstalled ? "✅ installed" : "⏭️  not installed")")
            
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
                    print("  ✅ Found \(artifacts.count) artifacts for \(toolName)")
                    let summary = await ToolArtifactSummary(tool: tool, artifacts: artifacts)
                    allToolSummaries.append(summary)
                } else {
                    print("  ⚠️  No artifacts found for \(toolName)")
                }
            } catch {
                // Log error but continue with other detectors
                print("  ❌ Error scanning \(toolName): \(error)")
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
    
    /// Xcode Containers path is intentionally ignored as it is typically empty in sandboxed contexts.
    func xcodeContainersDirectory() -> URL? { return nil }
}

