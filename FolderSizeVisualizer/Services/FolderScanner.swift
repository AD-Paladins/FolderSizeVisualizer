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

    func scan(
        root: URL,
        progress: @escaping (Double) async -> Void
    ) async throws -> ScanResult {

        let fileManager = FileManager.default
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .totalFileAllocatedSizeKey
        ]

        // Prepare the enumerator synchronously
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else {
            return ScanResult(folders: [])
        }

        let progressBatch = 500

        // Perform the heavy, synchronous enumeration work off the async actor context.
        // We collect folderSizes for TOP-LEVEL folders only (direct children of root)
        let (folderSizes, totalProcessed) = await Task.detached(priority: .utility) { () -> ([URL: Int64], Int) in
            var folderSizes: [URL: Int64] = [:]
            var processed = 0

            // Iterate using the Objective-C style API to avoid for-in (which calls makeIterator).
            while let item = enumerator.nextObject() as? URL {
                if Task.isCancelled { break }

                let values = try? item.resourceValues(forKeys: keys)
                let size = Int64(values?.totalFileAllocatedSize ?? 0)

                // Find the top-level folder (direct child of root)
                let topLevelFolder = Self.topLevelFolder(for: item, root: root)
                
                // Accumulate size to the top-level folder
                if let topLevel = topLevelFolder {
                    folderSizes[topLevel, default: 0] += size
                }

                processed += 1

                // Periodically yield to be responsive to cancellation.
                if processed % progressBatch == 0 {
                    await Task.yield()
                }
            }

            return (folderSizes, processed)
        }.value

        // Report a final progress update after enumeration completes.
        await progress(Double(totalProcessed))

        let entries = folderSizes
            .map { FolderEntry(url: $0.key, size: $0.value) }
            .sorted { $0.size > $1.size }

        return ScanResult(folders: entries)
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
