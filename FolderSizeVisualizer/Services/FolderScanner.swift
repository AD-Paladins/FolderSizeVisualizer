//
//  FolderEntry.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/4/26.
//

import Foundation

actor FolderScanner {

    struct ScanResult {
        let folders: [FolderEntry]
    }

    private var scanCache: [URL: ScanResult] = [:]

    func scan(
        root: URL,
        skipHiddenFiles: Bool = true,
        progress: @Sendable @escaping (Double, String) async -> Void
    ) async throws -> ScanResult {
        if let cachedResult = scanCache[root] {
            return cachedResult
        }

        let (folderSizes, totalProcessed, _) =
        await Task.detached(priority: .utility) { () -> ([URL: Int64], Int, URL?) in
            let fileManager = FileManager.default
            let keys: Set<URLResourceKey> = [
                .isDirectoryKey,
                .totalFileAllocatedSizeKey
            ]

            var enumeratorOptions: FileManager.DirectoryEnumerationOptions = []
            if skipHiddenFiles {
                enumeratorOptions.insert(.skipsHiddenFiles)
            }

            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: Array(keys),
                options: enumeratorOptions
            ) else {
                return ([:], 0, nil)
            }

            let topLevelURLs: [URL]
            do {
                var contentsOptions: FileManager.DirectoryEnumerationOptions = []
                if skipHiddenFiles {
                    contentsOptions.insert(.skipsHiddenFiles)
                }

                let children = try fileManager.contentsOfDirectory(
                    at: root,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: contentsOptions
                )
                topLevelURLs = children.filter { url in
                    let vals = try? url.resourceValues(forKeys: [.isDirectoryKey])
                    return vals?.isDirectory == true
                }
            } catch {
                topLevelURLs = []
            }
            let totalTopLevels = max(topLevelURLs.count, 1)
            var seenTopLevels = Set<URL>()

            var folderSizes: [URL: Int64] = [:]
            var processed = 0
            var lastProcessedItem: URL? = nil

            while let item = enumerator.nextObject() as? URL {
                if Task.isCancelled { break }

                let values = try? item.resourceValues(forKeys: keys)
                let size = Int64(values?.totalFileAllocatedSize ?? 0)

                let topLevelFolder = Self.topLevelFolder(for: item, root: root)

                if let topLevel = topLevelFolder {
                    folderSizes[topLevel, default: 0] += size

                    if seenTopLevels.insert(topLevel).inserted {
                        let fraction = min(Double(seenTopLevels.count) / Double(totalTopLevels), 0.95)
                        let name = topLevel.lastPathComponent.isEmpty ? topLevel.path : topLevel.lastPathComponent
                        await progress(fraction, name)
                    }
                }

                processed += 1
                lastProcessedItem = item

                if processed % 1000 == 0 {
                    await Task.yield()
                }
            }

            return (folderSizes, processed, lastProcessedItem)
        }.value

        let finalText = "Completed (\(totalProcessed) items)"
        await progress(1.0, finalText)

        let entries = folderSizes
            .map { FolderEntry(url: $0.key, size: $0.value) }
            .sorted { $0.size > $1.size }

        let result = ScanResult(folders: entries)

        scanCache[root] = result

        return result
    }
    
    /// Get cached result for a URL if it exists
    func getCachedResult(for url: URL) -> ScanResult? {
        scanCache[url]
    }
    
    /// Refresh a scan by invalidating its cache and subcaches
    func refreshScan(for url: URL) {
        // Remove the URL from cache
        scanCache.removeValue(forKey: url)
        
        // Remove all subcaches (URLs that start with this path)
        let urlPath = url.path
        let keysToRemove = scanCache.keys.filter { key in
            key.path.hasPrefix(urlPath + "/") || key.path.hasPrefix(urlPath)
        }
        keysToRemove.forEach { scanCache.removeValue(forKey: $0) }
    }
    
    /// Clear all cached results
    func clearCache() {
        scanCache.removeAll()
    }
    
    /// Finds the top-level folder (direct child of root) for a given item
    private static func topLevelFolder(for item: URL, root: URL) -> URL? {
        var current = item
        var parent = current.deletingLastPathComponent()

        let rootStd = root.standardizedFileURL
        let rootPath = rootStd.path

        while parent.standardizedFileURL.path != rootPath {
            current = parent
            parent = current.deletingLastPathComponent()

            if parent.path.count < root.path.count {
                return nil
            }
        }

        let topLevel = current.standardizedFileURL
        return topLevel.path == rootPath ? nil : topLevel
    }
}

