//
//  FolderSizeVisualizerTests.swift
//  FolderSizeVisualizerTests
//
//  Created by Paladines, Andres D. on 1/15/26.
//

import Foundation

@testable import FolderSizeVisualizer

struct FolderSizeVisualizerTestsHelper {

    /// Creates a temporary directory structure for scanning tests.
    /// Structure:
    /// root/
    ///   A/
    ///     sub1/file1 (≈1 KB)
    ///     sub2/file2 (≈512 B)
    ///   B/
    ///     file3 (≈2 KB)
    /// Returns the root URL and a mapping of top-level folder URL -> allocated size.
    static func makeTempDirectoryStructure() throws -> (root: URL, expected: [URL: Int64]) {
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
        let allocSub1 = try allocatedSize(of: dirASub1.appendingPathComponent("file1.bin"))
        let allocSub2 = try allocatedSize(of: dirASub2.appendingPathComponent("file2.bin"))
        let expectedA = allocSub1 + allocSub2
        let expectedB = try allocatedSize(of: dirB.appendingPathComponent("file3.bin"))

        return (root, [root.appendingPathComponent("A", isDirectory: true): expectedA,
                       root.appendingPathComponent("B", isDirectory: true): expectedB])
    }

    static func writeFile(at url: URL, size: Int) throws {
        let data = Data(count: size)
        try data.write(to: url, options: .atomic)
    }

    static func allocatedSize(of url: URL) throws -> Int64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey]
        let values = try url.resourceValues(forKeys: keys)
        return Int64(values.totalFileAllocatedSize ?? 0)
    }

    static func removeDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
