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
        // We collect folderSizes and a total processed count to allow progress reporting.
        let (folderSizes, totalProcessed) = await Task.detached(priority: .utility) { () -> ([URL: Int64], Int) in
            var folderSizes: [URL: Int64] = [:]
            var processed = 0

            // Iterate using the Objective-C style API to avoid for-in (which calls makeIterator).
            while let item = enumerator.nextObject() as? URL {
                if Task.isCancelled { break }

                let values = try? item.resourceValues(forKeys: keys)
                let isDirectory = values?.isDirectory ?? false
                let size = Int64(values?.totalFileAllocatedSize ?? 0)

                if isDirectory {
                    folderSizes[item, default: 0] += size
                } else {
                    let parent = item.deletingLastPathComponent()
                    folderSizes[parent, default: 0] += size
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
}
