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
        progress: @Sendable @escaping (Double, String) async -> Void
    ) async throws -> ScanResult {
        // Check cache first
        if let cachedResult = scanCache[root] {
            return cachedResult
        }
//        // Perform the heavy, synchronous enumeration work off the async actor context.
//        // We collect folderSizes for TOP-LEVEL folders only (direct children of root)
//        let (folderSizes, totalProcessed, lastItem) = await Task.detached(priority: .utility) { () -> ([URL: Int64], Int, URL?) in
//            var folderSizes: [URL: Int64] = [:]
//            var processed = 0
//            var lastProcessedItem: URL? = nil
//

        // Perform the heavy, synchronous enumeration work off the async actor context.
        // We collect folderSizes for TOP-LEVEL folders only (direct children of root)
        let (folderSizes, totalProcessed, lastItem) = await Task.detached(priority: .utility) { () -> ([URL: Int64], Int, URL?) in
            let fileManager = FileManager.default
            let keys: Set<URLResourceKey> = [
                .isDirectoryKey,
                .totalFileAllocatedSizeKey
            ]

            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles]
            ) else {
                return ([:], 0, nil)
            }

            let topLevelURLs: [URL]
            do {
                let children = try fileManager.contentsOfDirectory(
                    at: root,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
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

            // Iterate using the Objective-C style API to avoid for-in (which calls makeIterator).
            while let item = enumerator.nextObject() as? URL {
                if Task.isCancelled { break }

                let values = try? item.resourceValues(forKeys: keys)
                let size = Int64(values?.totalFileAllocatedSize ?? 0)

                // Find the top-level folder (direct child of root)
                let topLevelFolder = Self.topLevelFolder(for: item, root: root)

                // Accumulate size to the top-level folder and update progress when we first see a new top-level
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

                // Periodically yield to keep the system responsive.
                if processed % 1000 == 0 {
                    await Task.yield()
                }
            }

            return (folderSizes, processed, lastProcessedItem)
        }.value

        // Report final progress update after enumeration completes.
        let finalText = "Completed (\(totalProcessed) items)"
        await progress(1.0, finalText)

        let entries = folderSizes
            .map { FolderEntry(url: $0.key, size: $0.value) }
            .sorted { $0.size > $1.size }

        let result = ScanResult(folders: entries)
        
        // Cache the result
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
        
        // Walk up the directory tree until we find the direct child of root
        while parent.path != root.path {
            current = parent
            parent = current.deletingLastPathComponent()
            
            // Safety check: if we've gone above root somehow, return nil
            if parent.path.count < root.path.count {
                return nil
            }
        }
        
        // current is now the direct child of root
        return current == root ? nil : current
    }
}

