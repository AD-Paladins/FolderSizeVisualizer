import Foundation
import Testing

@testable import FolderSizeVisualizer

@Suite("VenvArtifactDetector Unit Tests", .serialized)
@MainActor
struct VenvArtifactDetectorTests {

    private let bookmarkKey = "bookmark_venvProjectRoots"

    // MARK: - Helpers

    private func createValidVenv(at parent: URL, name: String) throws -> URL {
        let venvDir = parent.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: venvDir, withIntermediateDirectories: true)
        try Data("home = /usr/bin\ninclude-system-site-packages = false\nversion = 3.12".utf8)
            .write(to: venvDir.appendingPathComponent("pyvenv.cfg"))
        let binDir = venvDir.appendingPathComponent("bin", isDirectory: true)
        try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
        try Data().write(to: binDir.appendingPathComponent("python"))
        return venvDir
    }

    private func createDirWithoutPyvenvCfg(at parent: URL, name: String) throws -> URL {
        let dir = parent.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let binDir = dir.appendingPathComponent("bin", isDirectory: true)
        try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
        try Data().write(to: binDir.appendingPathComponent("python"))
        return dir
    }

    private func createDirWithoutPythonBin(at parent: URL, name: String) throws -> URL {
        let dir = parent.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("home = /usr/bin".utf8).write(to: dir.appendingPathComponent("pyvenv.cfg"))
        return dir
    }

    private func withBookmark<T>(for url: URL, perform: () async throws -> T) async throws -> T {
        let original = UserDefaults.standard.data(forKey: bookmarkKey)
        let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(data, forKey: bookmarkKey)
        defer {
            if let original {
                UserDefaults.standard.set(original, forKey: bookmarkKey)
            } else {
                UserDefaults.standard.removeObject(forKey: bookmarkKey)
            }
        }
        return try await perform()
    }

    private func withoutBookmark<T>(perform: () async throws -> T) async rethrows -> T {
        let original = UserDefaults.standard.data(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        defer {
            if let original {
                UserDefaults.standard.set(original, forKey: bookmarkKey)
            } else {
                UserDefaults.standard.removeObject(forKey: bookmarkKey)
            }
        }
        return try await perform()
    }

    private func makeTempRoot() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FSVVenV-\(UUID().uuidString)", isDirectory: true)
    }

    // MARK: - isToolInstalled

    @Test("isToolInstalled returns false when no managed dirs or bookmark exist")
    func toolNotInstalledWhenNothingExists() async {
        let managedDirs = [
            DeveloperPaths.pipenvVenvs,
            DeveloperPaths.poetryVenvs,
            DeveloperPaths.virtualenvwrapperVenvs,
        ]
        let fm = FileManager.default
        for dir in managedDirs where fm.fileExists(atPath: dir.path) {
            return  // Managed dirs exist on this machine; pre-condition can't be met
        }

        await withoutBookmark {
            let detector = VenvArtifactDetector()
            let installed = await detector.isToolInstalled()
            #expect(!installed)
        }
    }

    @Test("isToolInstalled returns true when bookmark exists")
    func toolInstalledWhenBookmarkExists() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            let detector = VenvArtifactDetector()
            let installed = await detector.isToolInstalled()
            #expect(installed)
        }
    }

    // MARK: - Phase 2: Project roots with bookmark

    @Test("detects .venv at depth 1 with valid structure")
    func detectsDotVenvAtDepth1() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            let project = root.appendingPathComponent("my-project", isDirectory: true)
            try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
            _ = try createValidVenv(at: project, name: ".venv")

            let detector = VenvArtifactDetector()
            let artifacts = try await detector.detect { _, _ in }

            #expect(artifacts.count == 1)
            let artifact = try #require(artifacts.first)
            #expect(artifact.toolName == .venv)
            #expect(artifact.artifactType == "Virtual Environment")
            #expect(artifact.safeToDelete)
            #expect(artifact.riskLevel == .slowRebuild)
        }
    }

    @Test("detects venv (no dot prefix) at depth 1")
    func detectsVenvWithoutDot() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            let project = root.appendingPathComponent("my-project", isDirectory: true)
            try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
            _ = try createValidVenv(at: project, name: "venv")

            let detector = VenvArtifactDetector()
            let artifacts = try await detector.detect { _, _ in }
            #expect(artifacts.count == 1)
        }
    }

    @Test("skips candidate without pyvenv.cfg")
    func skipsDirWithoutPyvenvCfg() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            let project = root.appendingPathComponent("my-project", isDirectory: true)
            try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
            _ = try createDirWithoutPyvenvCfg(at: project, name: ".venv")

            let detector = VenvArtifactDetector()
            let artifacts = try await detector.detect { _, _ in }
            #expect(artifacts.isEmpty)
        }
    }

    @Test("skips candidate without bin/python")
    func skipsDirWithoutPythonBin() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            let project = root.appendingPathComponent("my-project", isDirectory: true)
            try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
            _ = try createDirWithoutPythonBin(at: project, name: ".venv")

            let detector = VenvArtifactDetector()
            let artifacts = try await detector.detect { _, _ in }
            #expect(artifacts.isEmpty)
        }
    }

    @Test("reports multiple valid venvs across different projects")
    func detectsMultipleVenvs() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            let a = root.appendingPathComponent("project-a", isDirectory: true)
            try FileManager.default.createDirectory(at: a, withIntermediateDirectories: true)
            _ = try createValidVenv(at: a, name: ".venv")

            let b = root.appendingPathComponent("project-b", isDirectory: true)
            try FileManager.default.createDirectory(at: b, withIntermediateDirectories: true)
            _ = try createValidVenv(at: b, name: ".venv")

            let detector = VenvArtifactDetector()
            let artifacts = try await detector.detect { _, _ in }
            #expect(artifacts.count == 2)
        }
    }

    @Test("filters out invalid venvs, only returns valid ones")
    func filtersInvalidVenvs() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            let valid = root.appendingPathComponent("valid-proj", isDirectory: true)
            try FileManager.default.createDirectory(at: valid, withIntermediateDirectories: true)
            _ = try createValidVenv(at: valid, name: ".venv")

            let noCfg = root.appendingPathComponent("no-cfg-proj", isDirectory: true)
            try FileManager.default.createDirectory(at: noCfg, withIntermediateDirectories: true)
            _ = try createDirWithoutPyvenvCfg(at: noCfg, name: ".venv")

            let noBin = root.appendingPathComponent("no-bin-proj", isDirectory: true)
            try FileManager.default.createDirectory(at: noBin, withIntermediateDirectories: true)
            _ = try createDirWithoutPythonBin(at: noBin, name: ".venv")

            let detector = VenvArtifactDetector()
            let artifacts = try await detector.detect { _, _ in }
            #expect(artifacts.count == 1)
        }
    }

    @Test("returns empty when no bookmark is stored")
    func handlesNoBookmarkGracefully() async throws {
        try await withoutBookmark {
            let detector = VenvArtifactDetector()
            let artifacts = try await detector.detect { _, _ in }
            #expect(artifacts.isEmpty)
        }
    }

    @Test("handles empty project root gracefully")
    func handlesEmptyProjectRoot() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            let detector = VenvArtifactDetector()
            let artifacts = try await detector.detect { _, _ in }
            #expect(artifacts.isEmpty)
        }
    }

    @Test("reports non-zero size for venv with data")
    func reportsSizeForVenv() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            let project = root.appendingPathComponent("my-project", isDirectory: true)
            try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
            let venvDir = try createValidVenv(at: project, name: ".venv")
            let sitePkg = venvDir.appendingPathComponent("lib/python3.12/site-packages", isDirectory: true)
            try FileManager.default.createDirectory(at: sitePkg, withIntermediateDirectories: true)
            try Data(repeating: 0xAA, count: 4096).write(to: sitePkg.appendingPathComponent("pkg.bin"))

            let detector = VenvArtifactDetector()
            let artifacts = try await detector.detect { _, _ in }
            #expect(artifacts.count == 1)
            let artifact = try #require(artifacts.first)
            #expect(artifact.sizeBytes > 0)
            #expect(artifact.underlyingPaths.count == 1)
            let path = try #require(artifact.underlyingPaths.first)
            #expect(path.lastPathComponent == ".venv")
        }
    }

    @Test("artifact includes project label in explanation")
    func artifactIncludesProjectLabel() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            let project = root.appendingPathComponent("my-project", isDirectory: true)
            try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
            _ = try createValidVenv(at: project, name: ".venv")

            let detector = VenvArtifactDetector()
            let artifacts = try await detector.detect { _, _ in }
            #expect(artifacts.count == 1)
            let artifact = try #require(artifacts.first)
            #expect(artifact.explanationText.contains("my-project"))
        }
    }

    @Test("calls progress handler during detection")
    func callsProgressHandler() async throws {
        let root = makeTempRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try await withBookmark(for: root) {
            _ = try createValidVenv(at: root.appendingPathComponent("proj", isDirectory: true), name: ".venv")

            actor Collector {
                var updates: [(Double, String)] = []
                func record(_ p: Double, _ m: String) { updates.append((p, m)) }
            }
            let collector = Collector()

            let detector = VenvArtifactDetector()
            _ = try await detector.detect { p, m in await collector.record(p, m) }

            let updates = await collector.updates
            #expect(!updates.isEmpty)
            let last = try #require(updates.last)
            #expect(last.0 >= 0.99)
        }
    }
}
