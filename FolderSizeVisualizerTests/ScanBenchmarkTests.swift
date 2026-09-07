//
//  ScanBenchmarkTests.swift
//  FolderSizeVisualizerTests
//
//  Benchmarks for measuring scan speed: real FolderScanner timing and a
//  controlled sequential-vs-parallel comparison that mirrors the parallel-scan
//  improvement (PR #20).
//

import Foundation
import Testing

@testable import FolderSizeVisualizer

@Suite("Scan Speed Benchmarks")
struct ScanBenchmarkTests {

    // MARK: - Real FolderScanner timing

    /// Generates a temporary directory tree with many files and measures how long
    /// `FolderScanner.scan()` takes to walk it, reporting the elapsed time in ms.
    @Test("FolderScanner walks a generated tree and reports elapsed time")
    func benchmarkFolderScannerTiming() async throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory
            .appendingPathComponent("FSVBench-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)

        // Create 50 subfolders, each with a few ~2 MB files (~100 MB total).
        let fileCountPerFolder = 4
        let bytesPerFile = Int64(2_000_000)
        var totalFiles = 0

        for i in 0..<50 {
            let sub = root.appendingPathComponent("folder-\(i)", isDirectory: true)
            try fm.createDirectory(at: sub, withIntermediateDirectories: true)
            for j in 0..<fileCountPerFolder {
                let data = Data(repeating: 0, count: Int(bytesPerFile))
                try await data.write(to: sub.appendingPathComponent("file-\(j).bin"))
                totalFiles += 1
            }
        }
        defer { try? fm.removeItem(at: root) }

        let scanner = FolderScanner()
        let start = DispatchTime.now().uptimeNanoseconds
        let result = try await scanner.scan(root: root) { _, _ in }
        let elapsedMs = (DispatchTime.now().uptimeNanoseconds - start) / 1_000_000

        print("""
        [BENCHMARK] FolderScanner
          tree: \(50) folders, \(totalFiles) files (~\(Int64(totalFiles) * bytesPerFile / 1_000_000) MB)
          elapsed: \(elapsedMs) ms
          folders reported: \(result.folders.count)
        """)

        #expect(result.folders.count == 50)
        #expect(elapsedMs >= 0)
    }

    // MARK: - Sequential vs. Parallel (synthetic detectors)

    /// Simulates N "detectors" each doing a fixed amount of blocking work, then
    /// compares sequential execution against `withTaskGroup`. This mirrors the PR #20
    /// parallel-scan change and should show a large speedup when N > 1.
    @Test("synthetic detectors: parallel is faster than sequential")
    func benchmarkParallelVsSequential() async throws {
        let detectorCount = 8
        let workPerDetectorNs: UInt64 = 200_000_000 // ~200 ms of fake work each

        // --- Sequential: sum of all detectors ---
        let seqStart = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<detectorCount {
            Thread.sleep(forTimeInterval: Double(workPerDetectorNs) / 1_000_000_000)
        }
        let seqMs = (DispatchTime.now().uptimeNanoseconds - seqStart) / 1_000_000

        // --- Parallel: bounded by the slowest single detector ---
        let parStart = DispatchTime.now().uptimeNanoseconds
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<detectorCount {
                group.addTask {
                    Thread.sleep(forTimeInterval: Double(workPerDetectorNs) / 1_000_000_000)
                }
            }
        }
        let parMs = (DispatchTime.now().uptimeNanoseconds - parStart) / 1_000_000

        print("""
        [BENCHMARK] parallel vs sequential
          detectors: \(detectorCount), work/detector: \(Int(workPerDetectorNs / 1_000_000)) ms
          sequential: \(seqMs) ms (sum of all)
          parallel:   \(parMs) ms (bounded by slowest)
          speedup:    \(Int64(seqMs / max(parMs, 1)))x
        """)

        #expect(seqMs > 0)
        #expect(parMs > 0)
        // Parallel should be dramatically faster than sequential.
        #expect(parMs < seqMs / 2)
    }
}
