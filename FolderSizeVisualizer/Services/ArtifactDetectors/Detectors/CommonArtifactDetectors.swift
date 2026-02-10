//
//  CommonArtifactDetectors.swift
//  FolderSizeVisualizer
//
//  Detectors for common developer tools: Node.js, Docker, Homebrew, Python, Rust, Android
//

import Foundation

// MARK: - Node.js Detector

actor NodeJSArtifactDetector: ArtifactDetector {
    nonisolated let tool: DeveloperTool = .nodeJS
    private let fileHelper = FileSystemHelper()
    
    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []
        
        await progress(0.3, "Scanning npm cache...")
        if let npmArtifact = await detectNpmCache() {
            artifacts.append(npmArtifact)
        }
        
        await progress(0.6, "Scanning Yarn cache...")
        if let yarnArtifact = await detectYarnCache() {
            artifacts.append(yarnArtifact)
        }
        
        await progress(1.0, "Completed Node.js scan")
        
        return artifacts
    }
    
    func isToolInstalled() async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["node"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func detectNpmCache() async -> DeveloperArtifact? {
        let cachePath = await DeveloperPaths.npmCache
        
        guard await fileHelper.exists(at: cachePath) else {
            return nil
        }
        
        let size = await fileHelper.directorySize(at: cachePath)
        let lastUsed = await fileHelper.lastAccessDate(at: cachePath)
        
        return await DeveloperArtifact(
            toolName: .nodeJS,
            artifactType: "npm Cache",
            sizeBytes: size,
            safeToDelete: true,
            riskLevel: .slowRebuild,
            rebuildCostEstimate: "Packages redownloaded on next install",
            lastUsedDate: lastUsed,
            explanationText: "npm's package cache. Deleting forces npm to redownload packages, but doesn't affect installed node_modules.",
            underlyingPaths: [cachePath]
        )
    }
    
    private func detectYarnCache() async -> DeveloperArtifact? {
        let cachePath = await DeveloperPaths.yarnCache
        
        guard await fileHelper.exists(at: cachePath) else {
            return nil
        }
        
        let size = await fileHelper.directorySize(at: cachePath)
        let lastUsed = await fileHelper.lastAccessDate(at: cachePath)
        
        return await DeveloperArtifact(
            toolName: .nodeJS,
            artifactType: "Yarn Cache",
            sizeBytes: size,
            safeToDelete: true,
            riskLevel: .slowRebuild,
            rebuildCostEstimate: "Packages redownloaded on next install",
            lastUsedDate: lastUsed,
            explanationText: "Yarn's package cache. Safe to delete - packages will be redownloaded when needed.",
            underlyingPaths: [cachePath]
        )
    }
}

// MARK: - Docker Detector

actor DockerArtifactDetector: ArtifactDetector {
    nonisolated let tool: DeveloperTool = .docker
    private let fileHelper = FileSystemHelper()
    
    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []
        
        await progress(0.5, "Analyzing Docker data...")
        if let dockerArtifact = await detectDockerData() {
            artifacts.append(dockerArtifact)
        }
        
        await progress(1.0, "Completed Docker scan")
        
        return artifacts
    }
    
    func isToolInstalled() async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["docker"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func detectDockerData() async -> DeveloperArtifact? {
        let dataPath = await DeveloperPaths.dockerData
        
        guard await fileHelper.exists(at: dataPath) else {
            return nil
        }
        
        let size = await fileHelper.directorySize(at: dataPath)
        let lastUsed = await fileHelper.lastAccessDate(at: dataPath)
        
        return await DeveloperArtifact(
            toolName: .docker,
            artifactType: "Docker Data",
            sizeBytes: size,
            safeToDelete: false,
            riskLevel: .unsafe,
            rebuildCostEstimate: "Cannot rebuild - contains volumes and container data",
            lastUsedDate: lastUsed,
            explanationText: "Contains Docker images, containers, and volumes. Deleting will remove all Docker data. Use 'docker system prune' for safe cleanup instead.",
            underlyingPaths: [dataPath]
        )
    }
}

// MARK: - Homebrew Detector

actor HomebrewArtifactDetector: ArtifactDetector {
    nonisolated let tool: DeveloperTool = .homebrew
    private let fileHelper = FileSystemHelper()
    
    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []
        
        await progress(0.5, "Scanning Homebrew cache...")
        if let cacheArtifact = await detectHomebrewCache() {
            artifacts.append(cacheArtifact)
        }
        
        await progress(1.0, "Completed Homebrew scan")
        
        return artifacts
    }
    
    func isToolInstalled() async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["brew"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func detectHomebrewCache() async -> DeveloperArtifact? {
        let cachePath = await DeveloperPaths.homebrewCache
        
        guard await fileHelper.exists(at: cachePath) else {
            return nil
        }
        
        let size = await fileHelper.directorySize(at: cachePath)
        let lastUsed = await fileHelper.lastAccessDate(at: cachePath)
        
        return await DeveloperArtifact(
            toolName: .homebrew,
            artifactType: "Download Cache",
            sizeBytes: size,
            safeToDelete: true,
            riskLevel: .safe,
            rebuildCostEstimate: "Packages redownloaded if needed",
            lastUsedDate: lastUsed,
            explanationText: "Homebrew's download cache for packages. Safe to delete - run 'brew cleanup' for selective cleanup.",
            underlyingPaths: [cachePath]
        )
    }
}

// MARK: - Python Detector

actor PythonArtifactDetector: ArtifactDetector {
    nonisolated let tool: DeveloperTool = .python
    private let fileHelper = FileSystemHelper()
    
    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []
        
        await progress(0.3, "Scanning pip cache...")
        if let pipArtifact = await detectPipCache() {
            artifacts.append(pipArtifact)
        }
        
        await progress(0.6, "Scanning Poetry cache...")
        if let poetryArtifact = await detectPoetryCache() {
            artifacts.append(poetryArtifact)
        }
        
        await progress(1.0, "Completed Python scan")
        
        return artifacts
    }
    
    func isToolInstalled() async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["python3"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func detectPipCache() async -> DeveloperArtifact? {
        let cachePath = await DeveloperPaths.pipCache
        
        guard await fileHelper.exists(at: cachePath) else {
            return nil
        }
        
        let size = await fileHelper.directorySize(at: cachePath)
        let lastUsed = await fileHelper.lastAccessDate(at: cachePath)
        
        return await DeveloperArtifact(
            toolName: .python,
            artifactType: "pip Cache",
            sizeBytes: size,
            safeToDelete: true,
            riskLevel: .safe,
            rebuildCostEstimate: "Packages redownloaded on next install",
            lastUsedDate: lastUsed,
            explanationText: "pip's package cache. Safe to delete - packages will be redownloaded when needed.",
            underlyingPaths: [cachePath]
        )
    }
    
    private func detectPoetryCache() async -> DeveloperArtifact? {
        let cachePath = await DeveloperPaths.poetryCache
        
        guard await fileHelper.exists(at: cachePath) else {
            return nil
        }
        
        let size = await fileHelper.directorySize(at: cachePath)
        let lastUsed = await fileHelper.lastAccessDate(at: cachePath)
        
        return await DeveloperArtifact(
            toolName: .python,
            artifactType: "Poetry Cache",
            sizeBytes: size,
            safeToDelete: true,
            riskLevel: .safe,
            rebuildCostEstimate: "Packages redownloaded on next install",
            lastUsedDate: lastUsed,
            explanationText: "Poetry's package cache. Safe to delete - packages will be redownloaded when needed.",
            underlyingPaths: [cachePath]
        )
    }
}

// MARK: - Rust Detector

actor RustArtifactDetector: ArtifactDetector {
    nonisolated let tool: DeveloperTool = .rust
    private let fileHelper = FileSystemHelper()
    
    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []
        
        await progress(0.3, "Scanning Cargo registry...")
        if let registryArtifact = await detectCargoRegistry() {
            artifacts.append(registryArtifact)
        }
        
        await progress(0.6, "Scanning Cargo git cache...")
        if let gitArtifact = await detectCargoGit() {
            artifacts.append(gitArtifact)
        }
        
        await progress(1.0, "Completed Rust scan")
        
        return artifacts
    }
    
    func isToolInstalled() async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["cargo"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func detectCargoRegistry() async -> DeveloperArtifact? {
        let registryPath = await DeveloperPaths.cargoRegistry
        
        guard await fileHelper.exists(at: registryPath) else {
            return nil
        }
        
        let size = await fileHelper.directorySize(at: registryPath)
        let lastUsed = await fileHelper.lastAccessDate(at: registryPath)
        
        return await DeveloperArtifact(
            toolName: .rust,
            artifactType: "Cargo Registry",
            sizeBytes: size,
            safeToDelete: true,
            riskLevel: .slowRebuild,
            rebuildCostEstimate: "Crates redownloaded on next build",
            lastUsedDate: lastUsed,
            explanationText: "Cargo's crate registry cache. Safe to delete - crates will be redownloaded and recompiled.",
            underlyingPaths: [registryPath]
        )
    }
    
    private func detectCargoGit() async -> DeveloperArtifact? {
        let gitPath = await DeveloperPaths.cargoGit
        
        guard await fileHelper.exists(at: gitPath) else {
            return nil
        }
        
        let size = await fileHelper.directorySize(at: gitPath)
        let lastUsed = await fileHelper.lastAccessDate(at: gitPath)
        
        return await DeveloperArtifact(
            toolName: .rust,
            artifactType: "Cargo Git Cache",
            sizeBytes: size,
            safeToDelete: true,
            riskLevel: .slowRebuild,
            rebuildCostEstimate: "Git dependencies redownloaded on next build",
            lastUsedDate: lastUsed,
            explanationText: "Cargo's git dependency cache. Safe to delete - dependencies will be re-cloned when needed.",
            underlyingPaths: [gitPath]
        )
    }
}

// MARK: - Android Detector

actor AndroidArtifactDetector: ArtifactDetector {
    nonisolated let tool: DeveloperTool = .androidSDK
    private let fileHelper = FileSystemHelper()
    
    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []
        
        await progress(0.3, "Scanning Android SDK...")
        let sdkArtifacts = await detectAndroidSDK()
        artifacts.append(contentsOf: sdkArtifacts)
        
        await progress(0.7, "Scanning AVD...")
        let avdArtifacts = await detectAndroidAVD()
        artifacts.append(contentsOf: avdArtifacts)
        
        await progress(1.0, "Completed Android scan")
        
        return artifacts
    }
    
    func isToolInstalled() async -> Bool {
        await fileHelper.exists(at: DeveloperPaths.androidSDK)
    }
    
    private func detectAndroidSDK() async -> [DeveloperArtifact] {
        let sdkPath = await DeveloperPaths.androidSDK
        
        guard await fileHelper.exists(at: sdkPath) else {
            return []
        }
        
        let size = await fileHelper.directorySize(at: sdkPath)
        let lastUsed = await fileHelper.lastAccessDate(at: sdkPath)
        
        let artifact = await DeveloperArtifact(
            toolName: .androidSDK,
            artifactType: "Android SDK",
            sizeBytes: size,
            safeToDelete: false,
            riskLevel: .unsafe,
            rebuildCostEstimate: "Cannot rebuild - requires manual reinstallation",
            lastUsedDate: lastUsed,
            explanationText: "Android SDK installation. Contains platform tools, build tools, and system images. Do not delete unless removing Android development entirely.",
            underlyingPaths: [sdkPath]
        )
        
        return [artifact]
    }
    
    private func detectAndroidAVD() async -> [DeveloperArtifact] {
        let avdPath = await DeveloperPaths.androidAVD
        
        guard await fileHelper.exists(at: avdPath) else {
            return []
        }
        
        let avdDirs = await fileHelper.listDirectories(at: avdPath)
        var artifacts: [DeveloperArtifact] = []
        
        for avdDir in avdDirs {
            let size = await fileHelper.directorySize(at: avdDir)
            let lastUsed = await fileHelper.lastAccessDate(at: avdDir)
            
            let artifact = await DeveloperArtifact(
                toolName: .androidSDK,
                artifactType: "Android Virtual Device",
                sizeBytes: size,
                safeToDelete: true,
                riskLevel: .safe,
                rebuildCostEstimate: "Recreate in minutes via Android Studio",
                lastUsedDate: lastUsed,
                explanationText: "Android Virtual Device: \(avdDir.lastPathComponent). Contains emulator system and user data. Safe to delete - recreate via AVD Manager.",
                underlyingPaths: [avdDir]
            )
            
            artifacts.append(artifact)
        }
        
        return artifacts
    }
}
