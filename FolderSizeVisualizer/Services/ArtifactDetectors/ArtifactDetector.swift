//
//  ArtifactDetector.swift
//  FolderSizeVisualizer
//
//  Protocol and base infrastructure for detecting developer artifacts
//

import Foundation
import AppKit

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
    
    enum BookmarkKey: String {
        case xcodeDerivedData
        case xcodeArchives
        case simulatorRuntimes
        case assetsRoot
        case androidSDK
        case androidAVD
        case dockerData
        case npmCache
        case yarnCache
        case pnpmCache
        case homebrewCache
        case pipCache
        case poetryCache
        case cargoRegistry
        case cargoGit
        case gitCache
        case llmCustomDirectories
        case venvProjectRoots
    }
    
    // MARK: - Security-scoped bookmarks

    private static func defaultsKey(for key: BookmarkKey) -> String { "bookmark_\(key.rawValue)" }

    /// Presents a folder picker (macOS) and stores a security-scoped bookmark for the given key.
    /// Async shim that hops to the main actor to interact with AppKit safely.
    @discardableResult
    nonisolated func requestAccessAndStoreBookmark(for key: BookmarkKey, startingAt directory: URL? = nil) async -> URL? {
        await MainActor.run { [directory] in
            return self._presentFolderPickerAndStoreBookmark(for: key, startingAt: directory)
        }
    }

    /// Main-actor implementation that interacts with NSOpenPanel.
    @MainActor
    private func _presentFolderPickerAndStoreBookmark(for key: BookmarkKey, startingAt directory: URL?) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        if let dir = directory { panel.directoryURL = dir }
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try url.bookmarkData(options: .withSecurityScope,
                                                includingResourceValuesForKeys: nil,
                                                relativeTo: nil)
                UserDefaults.standard.set(data, forKey: Self.defaultsKey(for: key))
                return url
            } catch {
                print("Failed to create bookmark for \(key): \(error)")
                return nil
            }
        }
        return nil
    }

    /// Resolves a previously stored security-scoped bookmark for the given key.
    func resolveBookmark(for key: BookmarkKey) -> URL? {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey(for: key)) else { return nil }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data,
                              options: [.withSecurityScope],
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
            if isStale {
                // Refresh bookmark
                let newData = try url.bookmarkData(options: .withSecurityScope,
                                                   includingResourceValuesForKeys: nil,
                                                   relativeTo: nil)
                UserDefaults.standard.set(newData, forKey: Self.defaultsKey(for: key))
            }
            return url
        } catch {
            print("Failed to resolve bookmark for \(key): \(error)")
            return nil
        }
    }

    /// Executes a block with security-scoped access if a bookmark exists for the key.
    func withScopedAccess<T>(for key: BookmarkKey, perform: (URL) -> T?) -> T? {
        guard let url = resolveBookmark(for: key) else { return nil }
        #if canImport(AppKit)
        let started = url.startAccessingSecurityScopedResource()
        defer { if started { url.stopAccessingSecurityScopedResource() } }
        #endif
        return perform(url)
    }

    /// Calculate total size of a directory
    func directorySize(at url: URL) async -> Int64 {
        await Task.detached(priority: .utility) {
            var totalSize: Int64 = 0
            let fm = FileManager.default

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
            let fm = FileManager.default
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
            let fm = FileManager.default
            
            // Ensure the base URL exists and is a directory before listing
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
                return []
            }

            // Attempt to access security-scoped resource if available
            var didStartAccess = false
            #if canImport(AppKit)
            if url.startAccessingSecurityScopedResource() {
                didStartAccess = true
            }
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            #endif
            
            // Try to list directly; if it fails due to permissions, allow user to grant access via bookmark
            let contents: [URL]
            if let direct = try? fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) {
                contents = direct
            } else {
                // Attempt via security-scoped bookmark if one exists for a known key matching this URL
                // Simple heuristic: map known keys to expected default paths and compare
                let mapping: [(BookmarkKey, URL)] = await [
                    (.xcodeDerivedData, DeveloperPaths.derivedData),
                    (.xcodeArchives, DeveloperPaths.xcodeArchives),
                    (.simulatorRuntimes, URL(fileURLWithPath: "/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime")),
                    (.assetsRoot, URL(fileURLWithPath: "/System/Library/AssetsV2")),
                    (.androidSDK, DeveloperPaths.androidSDK),
                    (.androidAVD, DeveloperPaths.androidAVD),
                    (.dockerData, DeveloperPaths.dockerData),
                    (.npmCache, DeveloperPaths.npmCache),
                    (.yarnCache, DeveloperPaths.yarnCache),
                    (.pnpmCache, DeveloperPaths.pnpmCache),
                    (.homebrewCache, DeveloperPaths.homebrewCache),
                    (.pipCache, DeveloperPaths.pipCache),
                    (.poetryCache, DeveloperPaths.poetryCache),
                    (.cargoRegistry, DeveloperPaths.cargoRegistry),
                    (.cargoGit, DeveloperPaths.cargoGit),
                    (.gitCache, DeveloperPaths.gitCache)
                ]
                let matchedKey = mapping.first { $0.1.standardizedFileURL.path == url.standardizedFileURL.path }?.0
                if let key = matchedKey, let securedURL = await self.resolveBookmark(for: key) {
                    #if canImport(AppKit)
                    let started = securedURL.startAccessingSecurityScopedResource()
                    defer { if started { securedURL.stopAccessingSecurityScopedResource() } }
                    #endif
                    contents = (try? fm.contentsOfDirectory(
                        at: securedURL,
                        includingPropertiesForKeys: [.isDirectoryKey],
                        options: [.skipsHiddenFiles]
                    )) ?? []
                } else {
                    // No bookmark available; return empty and let caller prompt user via requestAccessAndStoreBookmark
                    return []
                }
            }

            // Only return children that are readable directories
            return contents.compactMap { childURL in
                // Skip if we cannot get attributes (e.g., permissions)
                guard let values = try? childURL.resourceValues(forKeys: [.isDirectoryKey]),
                      values.isDirectory == true else {
                    return nil
                }
                // Verify readability to avoid throwing later
                var childIsDir: ObjCBool = false
                guard fm.fileExists(atPath: childURL.path, isDirectory: &childIsDir), childIsDir.boolValue else {
                    return nil
                }
                return childURL
            }
        }.value
    }
    
    /// Check if a path exists
    func exists(at url: URL) async -> Bool {
        await Task.detached {
            let fm = FileManager.default
            return fm.fileExists(atPath: url.path)
        }.value
    }

    /// Read the full contents of a small text file (best effort, for config files).
    func readTextFile(at url: URL) async -> String? {
        await Task.detached {
            try? String(contentsOf: url, encoding: .utf8)
        }.value
    }
    
    /// Check if a path is a directory
    func isDirectory(at url: URL) async -> Bool {
        await Task.detached {
            let fm = FileManager.default
            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: url.path, isDirectory: &isDir)
            return exists && isDir.boolValue
        }.value
    }
    
    /// Delete a file or directory
    func delete(at url: URL) async throws {
        try await Task.detached {
            let fm = FileManager.default
            try fm.removeItem(at: url)
        }.value
    }
}

// MARK: - Common Path Utilities

/// Utility for finding common developer tool paths
enum DeveloperPaths {
    static let home = URL.userHome
    
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
    static let simulators = URL(string: "/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime")!
    static let simulatorVolumes = URL(string: "/Library/Developer/CoreSimulator/Volumes")!
    
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
    static let homebrewCellar = URL(string: "/opt/homebrew/Cellar")!
    
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

    // LLMs
    static let ollamaModels = home
        .appendingPathComponent(".ollama/models")
    static let huggingfaceCache = home
        .appendingPathComponent(".cache/huggingface")
    static let mlxModels = home
        .appendingPathComponent(".cache/mlx")
    static let lmStudioModels = home
        .appendingPathComponent(".lm-studio/models")

    // Python virtual environments
    static let pipenvVenvs = home.appendingPathComponent(".local/share/virtualenvs")
    static let poetryVenvs = home.appendingPathComponent(".cache/pypoetry/virtualenvs")
    static let virtualenvwrapperVenvs = home.appendingPathComponent(".virtualenvs")
}

