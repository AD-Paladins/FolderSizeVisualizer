//
//  ArtifactDetector.swift
//  FolderSizeVisualizer
//
//  Protocol and base infrastructure for detecting developer artifacts
//

import Foundation

// MARK: - Artifact Detector Protocol

/// Protocol that all artifact detectors must implement
protocol ArtifactDetector: Sendable {
    /// The tool this detector is responsible for
    nonisolated var tool: DeveloperTool { get }
    
    /// Detect all artifacts for this tool
    /// - Parameter progress: Callback for reporting progress (0.0 to 1.0)
    /// - Returns: Array of detected artifacts
    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact]
    
    /// Check if this tool is installed on the system
    func isToolInstalled() async -> Bool
}

// MARK: - File System Utilities

/// Helper utilities for artifact detection
actor FileSystemHelper {
    
    /// Calculate total size of a directory
    func directorySize(at url: URL) async -> Int64 {
        await Task.detached(priority: .utility) {
            var totalSize: Int64 = 0
            let fm = FileManager()

            guard let enumerator = fm.enumerator(
                at: url,
                includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
                options: [.skipsHiddenFiles]
            ) else {
                return 0
            }

            while let fileURL = enumerator.nextObject() as? URL {
                if Task.isCancelled { break }

                let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                totalSize += Int64(values?.totalFileAllocatedSize ?? 0)

                // Yield periodically
                if totalSize % 100_000 == 0 {
                    await Task.yield()
                }
            }

            return totalSize
        }.value
    }
    
    /// Get modification date of a file or directory
    func modificationDate(at url: URL) async -> Date? {
        await Task.detached {
            let fm = FileManager()
            let values = try? fm.attributesOfItem(atPath: url.path)
            return values?[.modificationDate] as? Date
        }.value
    }
    
    /// Get last access date (approximation using modification date)
    func lastAccessDate(at url: URL) async -> Date? {
        await modificationDate(at: url)
    }
    
    /// List directories in a path
    func listDirectories(at url: URL) async -> [URL] {
        await Task.detached {
            let fm = FileManager()
            guard let contents = try? fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                return []
            }

            return contents.filter { url in
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
                return values?.isDirectory == true
            }
        }.value
    }
    
    /// Check if a path exists
    func exists(at url: URL) async -> Bool {
        await Task.detached {
            let fm = FileManager()
            return fm.fileExists(atPath: url.path)
        }.value
    }
    
    /// Check if a path is a directory
    func isDirectory(at url: URL) async -> Bool {
        await Task.detached {
            let fm = FileManager()
            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: url.path, isDirectory: &isDir)
            return exists && isDir.boolValue
        }.value
    }
    
    /// Delete a file or directory
    func delete(at url: URL) async throws {
        try await Task.detached {
            let fm = FileManager()
            try fm.removeItem(at: url)
        }.value
    }
}

// MARK: - Common Path Utilities

/// Utility for finding common developer tool paths
enum DeveloperPaths {
    static let home = FileManager.default.homeDirectoryForCurrentUser
    
    // Xcode paths
    static let derivedData = home
        .appendingPathComponent("Library/Developer/Xcode/DerivedData")
    static let xcodeArchives = home
        .appendingPathComponent("Library/Developer/Xcode/Archives")
    static let deviceSupport = home
        .appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport")
    static let deviceLogs = home
        .appendingPathComponent("Library/Developer/Xcode/iOS Device Logs")
    
    // Simulators
    static let simulators = home
        .appendingPathComponent("Library/Developer/CoreSimulator/Devices")
    static let simulatorCaches = home
        .appendingPathComponent("Library/Developer/CoreSimulator/Caches")
    
    // Android
    static let androidSDK = home
        .appendingPathComponent("Library/Android/sdk")
    static let androidAVD = home
        .appendingPathComponent(".android/avd")
    
    // Docker
    static let dockerData = home
        .appendingPathComponent("Library/Containers/com.docker.docker/Data")
    
    // Node.js
    static let npmCache = home
        .appendingPathComponent(".npm")
    static let yarnCache = home
        .appendingPathComponent("Library/Caches/Yarn")
    static let pnpmCache = home
        .appendingPathComponent("Library/pnpm")
    
    // Homebrew
    static let homebrewCache = home
        .appendingPathComponent("Library/Caches/Homebrew")
    
    // Python
    static let pipCache = home
        .appendingPathComponent("Library/Caches/pip")
    static let poetryCache = home
        .appendingPathComponent("Library/Caches/pypoetry")
    
    // Rust
    static let cargoRegistry = home
        .appendingPathComponent(".cargo/registry")
    static let cargoGit = home
        .appendingPathComponent(".cargo/git")
    
    // Git
    static let gitCache = home
        .appendingPathComponent("Library/Caches/git")
}

