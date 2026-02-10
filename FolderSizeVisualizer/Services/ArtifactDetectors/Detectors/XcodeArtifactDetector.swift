//
//  XcodeArtifactDetector.swift
//  FolderSizeVisualizer
//
//  Detects Xcode-related artifacts (DerivedData, Archives, DeviceSupport)
//

import Foundation

actor XcodeArtifactDetector: ArtifactDetector {
    nonisolated let tool: DeveloperTool = .xcode
    private let fileHelper = FileSystemHelper()
    
    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []
        
        // Detect DerivedData (safe to delete, slow rebuild)
        await progress(0.1, "Scanning DerivedData...")
        let derivedDataArtifacts = await detectDerivedData()
        artifacts.append(contentsOf: derivedDataArtifacts)
        
        // Detect Archives (unsafe - contains signed builds)
        await progress(0.4, "Scanning Archives...")
        let archiveArtifacts = await detectArchives()
        artifacts.append(contentsOf: archiveArtifacts)
        
        // Detect Device Support (safe to delete, redownloaded when needed)
        await progress(0.6, "Scanning Device Support...")
        let deviceSupportArtifacts = await detectDeviceSupport()
        artifacts.append(contentsOf: deviceSupportArtifacts)
        
        // Detect Device Logs (safe to delete)
        await progress(0.8, "Scanning Device Logs...")
        let deviceLogArtifacts = await detectDeviceLogs()
        artifacts.append(contentsOf: deviceLogArtifacts)
        
        await progress(1.0, "Completed Xcode scan")
        
        return artifacts
    }
    
    func isToolInstalled() async -> Bool {
        let xcodePath = URL(fileURLWithPath: "/Applications/Xcode.app")
        return await fileHelper.exists(at: xcodePath)
    }
    
    // MARK: - DerivedData Detection
    
    private func detectDerivedData() async -> [DeveloperArtifact] {
        let derivedDataPath = await DeveloperPaths.derivedData
        
        print("    📂 Checking DerivedData at: \(derivedDataPath.path)")
        
        guard await fileHelper.exists(at: derivedDataPath) else {
            print("    ❌ DerivedData directory does not exist")
            return []
        }
        
        let projectDirs = await fileHelper.listDirectories(at: derivedDataPath)
        print("    📁 Found \(projectDirs.count) project directories")
        var artifacts: [DeveloperArtifact] = []
        
        for projectDir in projectDirs {
            let size = await fileHelper.directorySize(at: projectDir)
            let lastUsed = await fileHelper.lastAccessDate(at: projectDir)
            
            let artifact = await DeveloperArtifact(
                toolName: .xcode,
                artifactType: "DerivedData",
                sizeBytes: size,
                safeToDelete: true,
                riskLevel: .slowRebuild,
                rebuildCostEstimate: "2-10 minutes per project",
                lastUsedDate: lastUsed,
                explanationText: "Build artifacts and indexes for \(projectDir.lastPathComponent). Xcode will rebuild these when you open the project. Deleting may fix build issues.",
                underlyingPaths: [projectDir]
            )
            
            artifacts.append(artifact)
        }
        
        return artifacts
    }
    
    // MARK: - Archives Detection
    
    private func detectArchives() async -> [DeveloperArtifact] {
        let archivesPath = await DeveloperPaths.xcodeArchives
        
        guard await fileHelper.exists(at: archivesPath) else {
            return []
        }
        
        // Archives are organized by date: Archives/YYYY-MM-DD/AppName.xcarchive
        let dateDirs = await fileHelper.listDirectories(at: archivesPath)
        var artifacts: [DeveloperArtifact] = []
        
        for dateDir in dateDirs {
            let archives = await fileHelper.listDirectories(at: dateDir)
            
            for archive in archives {
                let size = await fileHelper.directorySize(at: archive)
                let lastUsed = await fileHelper.modificationDate(at: archive)
                
                let artifact = await DeveloperArtifact(
                    toolName: .xcode,
                    artifactType: "Archive",
                    sizeBytes: size,
                    safeToDelete: false,
                    riskLevel: .unsafe,
                    rebuildCostEstimate: "Cannot rebuild - signed and versioned",
                    lastUsedDate: lastUsed,
                    explanationText: "Signed archive for \(archive.deletingPathExtension().lastPathComponent). Contains your built app with signatures and dSYMs. Only delete if you're certain you don't need this version.",
                    underlyingPaths: [archive]
                )
                
                artifacts.append(artifact)
            }
        }
        
        return artifacts
    }
    
    // MARK: - Device Support Detection
    
    private func detectDeviceSupport() async -> [DeveloperArtifact] {
        let deviceSupportPath = await DeveloperPaths.deviceSupport
        
        guard await fileHelper.exists(at: deviceSupportPath) else {
            return []
        }
        
        let versionDirs = await fileHelper.listDirectories(at: deviceSupportPath)
        var artifacts: [DeveloperArtifact] = []
        
        for versionDir in versionDirs {
            let size = await fileHelper.directorySize(at: versionDir)
            let lastUsed = await fileHelper.lastAccessDate(at: versionDir)
            
            let artifact = await DeveloperArtifact(
                toolName: .xcode,
                artifactType: "Device Support",
                sizeBytes: size,
                safeToDelete: true,
                riskLevel: .safe,
                rebuildCostEstimate: "Auto-redownloaded when connecting device",
                lastUsedDate: lastUsed,
                explanationText: "Debug symbols for iOS \(versionDir.lastPathComponent). Xcode automatically downloads these when you connect a physical device running this iOS version.",
                underlyingPaths: [versionDir]
            )
            
            artifacts.append(artifact)
        }
        
        return artifacts
    }
    
    // MARK: - Device Logs Detection
    
    private func detectDeviceLogs() async -> [DeveloperArtifact] {
        let deviceLogsPath = await DeveloperPaths.deviceLogs
        
        guard await fileHelper.exists(at: deviceLogsPath) else {
            return []
        }
        
        let deviceDirs = await fileHelper.listDirectories(at: deviceLogsPath)
        var artifacts: [DeveloperArtifact] = []
        
        for deviceDir in deviceDirs {
            let size = await fileHelper.directorySize(at: deviceDir)
            let lastUsed = await fileHelper.lastAccessDate(at: deviceDir)
            
            let artifact = await DeveloperArtifact(
                toolName: .xcode,
                artifactType: "Device Logs",
                sizeBytes: size,
                safeToDelete: true,
                riskLevel: .safe,
                rebuildCostEstimate: "No rebuild needed",
                lastUsedDate: lastUsed,
                explanationText: "Crash logs and console output from \(deviceDir.lastPathComponent). Safe to delete unless you need historical logs for debugging.",
                underlyingPaths: [deviceDir]
            )
            
            artifacts.append(artifact)
        }
        
        return artifacts
    }
}
