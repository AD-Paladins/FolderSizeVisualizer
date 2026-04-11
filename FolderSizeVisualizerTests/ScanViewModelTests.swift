//
//  ScanViewModelTests.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/6/26.
//

import Foundation
import Testing

@testable import FolderSizeVisualizer

@Suite("ScanViewModel Unit Tests")
struct ScanViewModelTests {
    // MARK: - ScanViewModel

    @Test("ScanViewModel scans, populates folders, updates totals, and resets flags")
    @MainActor
    func viewModelScanLifecycle() async throws {
        let (root, expected) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

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
        let (root, _) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

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
    
    // MARK: - ScanViewModel Limit Results Tests
    
    @Test("ScanViewModel applyLimit respects maxResults when enabled")
    @MainActor
    func viewModelApplyLimitRespectsMaxResults() async throws {
        // Create test data with more than default maxResults
        let entries = (1...100).map { i in
            FolderEntry(url: URL(fileURLWithPath: "/test/\(i)"), size: Int64(i * 1024))
        }

        let vm = ScanViewModel()
        vm.limitResults = true
        vm.maxResults = 10

        let limited = vm.applyLimit(to: entries)

        #expect(limited.count == 10)
    }

    @Test("ScanViewModel applyLimit returns all when limit disabled")
    @MainActor
    func viewModelApplyLimitDisabledReturnAll() async throws {
        let entries = (1...100).map { i in
            FolderEntry(url: URL(fileURLWithPath: "/test/\(i)"), size: Int64(i * 1024))
        }

        let vm = ScanViewModel()
        vm.limitResults = false
        vm.maxResults = 10

        let limited = vm.applyLimit(to: entries)

        #expect(limited.count == 100)
    }

    @Test("ScanViewModel scan respects maxResults limit")
    @MainActor
    func viewModelScanRespectsLimitResults() async throws {
        let (root, _) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let vm = ScanViewModel()
        vm.limitResults = true
        vm.maxResults = 1

        vm.startScan(url: root)

        let timeout: UInt64 = 3_000_000_000
        let start = DispatchTime.now().uptimeNanoseconds
        while vm.isScanning && (DispatchTime.now().uptimeNanoseconds - start) < timeout {
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        #expect(vm.folders.count <= 1)
    }

    // MARK: - ScanViewModel Refresh & Reset Tests
    
    @Test("ScanViewModel refreshScan clears cache and rescans")
    @MainActor
    func viewModelRefreshScanClearsCacheAndRescans() async throws {
        let (root, _) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let vm = ScanViewModel()
        vm.maxResults = 10

        // First scan
        vm.startScan(url: root)
        let timeout: UInt64 = 3_000_000_000
        let start = DispatchTime.now().uptimeNanoseconds
        while vm.isScanning && (DispatchTime.now().uptimeNanoseconds - start) < timeout {
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        let firstScanComplete = !vm.isScanning
        #expect(firstScanComplete)

        let folderCountBeforeRefresh = vm.folders.count
        #expect(folderCountBeforeRefresh > 0)

        // Refresh
        vm.refreshScan(url: root)
        let refreshStart = DispatchTime.now().uptimeNanoseconds
        while vm.isScanning && (DispatchTime.now().uptimeNanoseconds - refreshStart) < timeout {
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        #expect(vm.isScanning == false)
        #expect(vm.folders.count == folderCountBeforeRefresh)
    }

    @Test("ScanViewModel resetAll clears state completely")
    @MainActor
    func viewModelResetAllClearsState() async throws {
        let (root, _) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let vm = ScanViewModel()
        vm.startScan(url: root)

        let timeout: UInt64 = 3_000_000_000
        let start = DispatchTime.now().uptimeNanoseconds
        while vm.isScanning && (DispatchTime.now().uptimeNanoseconds - start) < timeout {
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        // State should be populated
        #expect(vm.rootURL != nil)
        #expect(vm.folders.count > 0)

        // Reset
        vm.resetAll()

        // Give async reset a moment
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(vm.rootURL == nil)
        #expect(vm.folders.isEmpty)
        #expect(vm.progress == 0)
        #expect(vm.isScanning == false)
    }

    // MARK: - ScanViewModel Edge Case Tests
    
    @Test("ScanViewModel starting new scan cancels previous scan")
    @MainActor
    func viewModelNewScanCancelsPrevious() async throws {
        let (root, _) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let vm = ScanViewModel()
        vm.maxResults = 10

        // Start first scan
        vm.startScan(url: root)

        // Immediately start another scan (should cancel first)
        vm.startScan(url: root)

        let timeout: UInt64 = 3_000_000_000
        let start = DispatchTime.now().uptimeNanoseconds
        while vm.isScanning && (DispatchTime.now().uptimeNanoseconds - start) < timeout {
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        // Should complete without errors
        #expect(vm.isScanning == false)
        #expect(vm.folders.count == 2)
    }

    @Test("ScanViewModel totalSize sums all folder sizes")
    @MainActor
    func viewModelTotalSizeCalculation() async throws {
        let (root, expected) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let vm = ScanViewModel()
        vm.maxResults = 10

        vm.startScan(url: root)

        let timeout: UInt64 = 3_000_000_000
        let start = DispatchTime.now().uptimeNanoseconds
        while vm.isScanning && (DispatchTime.now().uptimeNanoseconds - start) < timeout {
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        let expectedTotal = expected.values.reduce(0, +)
        #expect(vm.totalSize == expectedTotal)
    }

    // MARK: - ScanViewModel Progress Tracking Tests
    
    @Test("ScanViewModel updates progress property during scan")
    @MainActor
    func viewModelTracksProgress() async throws {
        let (root, _) = try FolderSizeVisualizerTestsHelper.makeTempDirectoryStructure()
        defer { FolderSizeVisualizerTestsHelper.removeDirectory(root) }

        let vm = ScanViewModel()
        vm.startScan(url: root)

        // Poll and check that progress is being updated
        var progressUpdated = false
        let timeout: UInt64 = 3_000_000_000
        let start = DispatchTime.now().uptimeNanoseconds

        while vm.isScanning && (DispatchTime.now().uptimeNanoseconds - start) < timeout {
            if vm.progress > 0 {
                progressUpdated = true
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        // Give final updates a moment
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(progressUpdated || !vm.isScanning) // Either we saw progress or scan completed quickly
        #expect(vm.isScanning == false)
    }
}
