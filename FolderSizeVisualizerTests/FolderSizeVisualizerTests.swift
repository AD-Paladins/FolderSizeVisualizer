//
//  FolderSizeVisualizerTests.swift
//  FolderSizeVisualizerTests
//
//  Created by Paladines, Andres D. on 1/15/26.
//

import Foundation
import Testing
@testable import FolderSizeVisualizer

@Suite("FolderSizeVisualizer Unit Tests")
struct FolderSizeVisualizerTests {

    // MARK: - Helpers

    /// Creates a temporary directory structure for scanning tests.
    /// Structure:
    /// root/
    ///   A/
    ///     sub1/file1 (≈1 KB)
    ///     sub2/file2 (≈512 B)
    ///   B/
    ///     file3 (≈2 KB)
    /// Returns the root URL and a mapping of top-level folder URL -> allocated size.
    private func makeTempDirectoryStructure() throws -> (root: URL, expected: [URL: Int64]) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("FSVTests-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)

        let dirA = root.appendingPathComponent("A", isDirectory: true)
        let dirASub1 = dirA.appendingPathComponent("sub1", isDirectory: true)
        let dirASub2 = dirA.appendingPathComponent("sub2", isDirectory: true)
        let dirB = root.appendingPathComponent("B", isDirectory: true)

        try fm.createDirectory(at: dirASub1, withIntermediateDirectories: true)
        try fm.createDirectory(at: dirASub2, withIntermediateDirectories: true)
        try fm.createDirectory(at: dirB, withIntermediateDirectories: true)

        // Create files with requested logical sizes.
        try writeFile(at: dirASub1.appendingPathComponent("file1.bin"), size: 1_024)
        try writeFile(at: dirASub2.appendingPathComponent("file2.bin"), size: 512)
        try writeFile(at: dirB.appendingPathComponent("file3.bin"), size: 2_048)

        // Compute allocated sizes (since scanner uses totalFileAllocatedSizeKey).
        let expectedA = try allocatedSize(of: dirASub1.appendingPathComponent("file1.bin"))
                      + try allocatedSize(of: dirASub2.appendingPathComponent("file2.bin"))
        let expectedB = try allocatedSize(of: dirB.appendingPathComponent("file3.bin"))

        return (root, [root.appendingPathComponent("A", isDirectory: true): expectedA,
                       root.appendingPathComponent("B", isDirectory: true): expectedB])
    }

    private func writeFile(at url: URL, size: Int) throws {
        let data = Data(count: size)
        try data.write(to: url, options: .atomic)
    }

    private func allocatedSize(of url: URL) throws -> Int64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey]
        let values = try url.resourceValues(forKeys: keys)
        return Int64(values.totalFileAllocatedSize ?? 0)
    }

    private func removeDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - FolderEntry

    @Test("FolderEntry name uses lastPathComponent when available")
    func folderEntryNameUsesLastPathComponent() async throws {
        let url = URL(fileURLWithPath: "/Users/test/Documents")
        let entry = FolderEntry(url: url, size: 0)
        #expect(entry.name == "Documents")
    }

    @Test("FolderEntry name falls back to full path when lastPathComponent is empty (root)")
    func folderEntryNameFallsBackToPathForRoot() async throws {
        let rootURL = URL(fileURLWithPath: "/")
        let entry = FolderEntry(url: rootURL, size: 0)
        // For root, lastPathComponent is "/" on macOS, so `name` should be "/".
        #expect(entry.name == "/")
    }

    // MARK: - FolderScanner

    @Test("FolderScanner aggregates sizes by top-level folders and sorts descending")
    func scannerAggregatesAndSorts() async throws {
        let (root, expected) = try makeTempDirectoryStructure()
        defer { removeDirectory(root) }

        let scanner = FolderScanner()
        let result = try await scanner.scan(root: root) { _ in }

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

    // MARK: - ScanViewModel

    @Test("ScanViewModel scans, populates folders, updates totals, and resets flags")
    @MainActor
    func viewModelScanLifecycle() async throws {
        let (root, expected) = try makeTempDirectoryStructure()
        defer { removeDirectory(root) }

        let vm = ScanViewModel()
        vm.maxResults = 10

        vm.startScan(url: root)

        // Poll until scanning finishes or timeout
        let timeout: UInt64 = 3_000_000_000 // 3 seconds
        let start = DispatchTime.now().uptimeNanoseconds
        while vm.isScanning && (DispatchTime.now().uptimeNanoseconds - start) < timeout {
            try await Task.sleep(nanoseconds: 50_000_000) // 50 ms
        }

        // After completion
        #expect(vm.isScanning == false)
        #expect(vm.rootURL == root)
        #expect(vm.folders.count == 2)

        let totalExpected = expected.values.reduce(0, +)
        #expect(vm.totalSize == totalExpected)

        // Progress should be within [0, +infinity). We don't assert 1.0 because it reports processed count.
        #expect(vm.progress >= 0)
    }

    @Test("ScanViewModel cancel sets scanning state to false immediately")
    @MainActor
    func viewModelCancel() async throws {
        let (root, _) = try makeTempDirectoryStructure()
        defer { removeDirectory(root) }

        let vm = ScanViewModel()
        vm.maxResults = 10

        vm.startScan(url: root)
        // Immediately cancel
        vm.cancelScan()

        // State should reflect cancellation right away
        #expect(vm.isScanning == false)

        // Give any background work a moment and ensure it doesn't flip back to true
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(vm.isScanning == false)
    }
}
