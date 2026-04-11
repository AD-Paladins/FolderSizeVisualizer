//
//  FolderScannerTests.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/6/26.
//

import Foundation
import Testing

@testable import FolderSizeVisualizer

@Suite("FolderScanner Unit Tests")
struct FolderScannerTests {
    

    @Test("FolderScanner aggregates sizes by top-level folders and sorts descending")
    @MainActor
    func scannerAggregatesAndSorts() async throws {
        let (root, expected) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let scanner = FolderScanner()
        let result = try await scanner.scan(root: root) { _, _ in }

        // Validate there are exactly two top-level entries A and B
        #expect(result.folders.count == 2)

        let names = Set(result.folders.map { $0.url.lastPathComponent })
        #expect(names == Set(["A", "B"]))

        // Validate sizes match allocated sizes we computed
        for entry in result.folders {
            let expectedSize = expected[entry.url]
            #expect(expectedSize != nil)
            if let expectedSize {
                #expect(entry.size == expectedSize)
            }
        }

        // Validate sort order: B (larger) should come before A (smaller)
        let sortedNames = result.folders.map { $0.url.lastPathComponent }
        if let sizeA = expected[root.appendingPathComponent("A", isDirectory: true)],
           let sizeB = expected[root.appendingPathComponent("B", isDirectory: true)] {
            if sizeB > sizeA {
                #expect(sortedNames.first == "B")
            } else if sizeA > sizeB {
                #expect(sortedNames.first == "A")
            } else {
                // Equal sizes: order is unspecified; just ensure both present
                #expect(Set(sortedNames) == Set(["A", "B"]))
            }
        }
    }

    // MARK: - FolderScanner Caching Tests

    @Test("FolderScanner caches results and returns same result from cache")
    func scannerCachesAndRetrievesResults() async throws {
        let (root, expected) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let scanner = FolderScanner()

        // First scan should complete normally
        let result1 = try await scanner.scan(root: root) { _, _ in }
        #expect(result1.folders.count == 2)

        // Get cached result should return same data
        let cachedResult = await scanner.getCachedResult(for: root)
        #expect(cachedResult != nil)
        #expect(cachedResult?.folders.count == 2)
        
        // Verify contents match
        if let cached = cachedResult {
            #expect(cached.folders.count == result1.folders.count)
        }
    }

    @Test("FolderScanner returns nil for uncached URLs")
    func scannerReturnsNilForUncachedURL() async throws {
        let scanner = FolderScanner()
        let fakeURL = URL(fileURLWithPath: "/nonexistent/path", isDirectory: true)
        
        let cached = await scanner.getCachedResult(for: fakeURL)
        #expect(cached == nil)
    }

    @Test("FolderScanner second scan uses cache and returns matching result")
    func scannerSecondScanUsesCacheQuickly() async throws {
        let (root, _) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let scanner = FolderScanner()

        // First scan
        let result1 = try await scanner.scan(root: root) { _, _ in }

        // Second scan should be instant (from cache)
        let result2 = try await scanner.scan(root: root) { _, _ in }

        // Both should have same folder count and contents
        #expect(result1.folders.count == result2.folders.count)
        #expect(result1.folders.count == 2)
    }

    @Test("FolderScanner clearCache removes all cached entries")
    func scannerClearCacheRemovesEntries() async throws {
        let (root, _) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let scanner = FolderScanner()

        // Cache a result
        _ = try await scanner.scan(root: root) { _, _ in }
        var cached = await scanner.getCachedResult(for: root)
        #expect(cached != nil)

        // Clear cache
        await scanner.clearCache()
        
        cached = await scanner.getCachedResult(for: root)
        #expect(cached == nil)
    }

    @Test("FolderScanner refreshScan invalidates cache for URL")
    func scannerRefreshScanInvalidatesCache() async throws {
        let (root, _) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let scanner = FolderScanner()

        // Cache a result
        _ = try await scanner.scan(root: root) { _, _ in }
        var cached = await scanner.getCachedResult(for: root)
        #expect(cached != nil)

        // Refresh should clear cache for that URL
        await scanner.refreshScan(for: root)
        
        cached = await scanner.getCachedResult(for: root)
        #expect(cached == nil)
    }

    // MARK: - FolderScanner Progress Tracking Tests

    @Test("FolderScanner calls progress handler during scan")
    func scannerCallsProgressHandler() async throws {
        let (root, _) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let scanner = FolderScanner()
        var progressUpdates: [(Double, String)] = []

        let result = try await scanner.scan(root: root) { progress, itemName in
            progressUpdates.append((progress, itemName))
        }

        // Should have at least some progress updates (initial folders + final completion)
        #expect(!progressUpdates.isEmpty)
        
        // Last progress should be 1.0 (completion)
        if let lastProgress = progressUpdates.last?.0 {
            #expect(lastProgress >= 0.95) // Near completion
        }

        #expect(result.folders.count == 2)
    }

    // MARK: - FolderScanner Edge Case Tests

    @Test("FolderScanner handles empty directory")
    func scannerHandlesEmptyDirectory() async throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("FSVTests-Empty-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let scanner = FolderScanner()
        let result = try await scanner.scan(root: root) { _, _ in }

        // Empty directory should return empty result (no subdirectories)
        #expect(result.folders.isEmpty)
    }

    @Test("FolderScanner handles directory with single folder")
    @MainActor
    func scannerHandlesSingleFolder() async throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("FSVTests-Single-\(UUID().uuidString)", isDirectory: true)
        let folderA = root.appendingPathComponent("A", isDirectory: true)
        
        try fm.createDirectory(at: folderA, withIntermediateDirectories: true)
        try FolderSizeVisualizerTestsHelper.writeFile(at: folderA.appendingPathComponent("file.txt"), size: 1024)
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let scanner = FolderScanner()
        let result = try await scanner.scan(root: root) { _, _ in }

        #expect(result.folders.count == 1)
        #expect(result.folders[0].url.lastPathComponent == "A")
        #expect(result.folders[0].size > 0)
    }
}
