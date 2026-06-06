//
//  VenvArtifactDetector.swift
//  FolderSizeVisualizer
//
//  Detects Python virtual environments in well-known manager dirs
//  and optionally in user-specified project root directories.
//

import Foundation

// MARK: - Venv metadata extracted from pyvenv.cfg + filesystem

struct VenvInfo: Sendable {
    let pythonVersion: String
    let pythonHome: String
    let packages: [String]
    let isWindows: Bool
    let venvName: String
}

actor VenvArtifactDetector: ArtifactDetector {
    nonisolated let tool: DeveloperTool = .venv
    private let fileHelper = FileSystemHelper()

    private let venvDirNames = ["venv", ".venv"]

    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []

        await progress(0.1, "Scanning known venv manager directories...")
        let managed = await scanManagedVenvDirs()
        artifacts.append(contentsOf: managed)

        await progress(0.5, "Scanning project roots...")
        let projectVenvs = await scanProjectRoots()
        artifacts.append(contentsOf: projectVenvs)

        await progress(1.0, "Completed venv scan")

        return artifacts
    }

    func isToolInstalled() async -> Bool {
        let dirs = [
            await DeveloperPaths.pipenvVenvs,
            await DeveloperPaths.poetryVenvs,
            await DeveloperPaths.virtualenvwrapperVenvs,
        ]
        for dir in dirs where await fileHelper.exists(at: dir) {
            return true
        }
        if await fileHelper.resolveBookmark(for: .venvProjectRoots) != nil {
            return true
        }
        return false
    }

    // MARK: - Phase 1: Known venv manager directories

    private func scanManagedVenvDirs() async -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []

        let dirs = [
            await DeveloperPaths.pipenvVenvs,
            await DeveloperPaths.poetryVenvs,
            await DeveloperPaths.virtualenvwrapperVenvs,
        ]

        for dir in dirs {
            guard await fileHelper.exists(at: dir) else { continue }

            let venvDirs = await fileHelper.listDirectories(at: dir)
            for venvDir in venvDirs {
                guard let info = await analyseVenv(at: venvDir) else { continue }

                let size = await fileHelper.directorySize(at: venvDir)
                let lastUsed = await fileHelper.lastAccessDate(at: venvDir)

                let artifact = await buildArtifact(
                    venvDir: venvDir,
                    info: info,
                    size: size,
                    lastUsed: lastUsed,
                    label: info.venvName
                )
                artifacts.append(artifact)
            }
        }

        return artifacts
    }

    // MARK: - Phase 2: User-specified project roots

    private func scanProjectRoots() async -> [DeveloperArtifact] {
        guard let rootDir = await fileHelper.resolveBookmark(for: .venvProjectRoots) else {
            return []
        }

        var artifacts: [DeveloperArtifact] = []
        let depth1Dirs = await fileHelper.listDirectories(at: rootDir)

        for candidate in depth1Dirs {
            let name = candidate.lastPathComponent

            if venvDirNames.contains(name) {
                if let info = await analyseVenv(at: candidate) {
                    let size = await fileHelper.directorySize(at: candidate)
                    let lastUsed = await fileHelper.lastAccessDate(at: candidate)
                    let label = candidate.deletingLastPathComponent().lastPathComponent
                    let artifact = await buildArtifact(venvDir: candidate, info: info, size: size, lastUsed: lastUsed, label: label)
                    artifacts.append(artifact)
                }
                continue
            }
            // Skip hidden directories and system files after venv check
            if name == ".DS_Store" || name.hasPrefix(".") { continue }

            guard await fileHelper.isDirectory(at: candidate) else { continue }

            if let childVenv = await findVenvInDir(candidate) {
                if let info = await analyseVenv(at: childVenv) {
                    let size = await fileHelper.directorySize(at: childVenv)
                    let lastUsed = await fileHelper.lastAccessDate(at: childVenv)
                    let artifact = await buildArtifact(venvDir: childVenv, info: info, size: size, lastUsed: lastUsed, label: candidate.lastPathComponent)
                    artifacts.append(artifact)
                }
            }
        }

        return artifacts
    }

    private func findVenvInDir(_ dir: URL) async -> URL? {
        for name in venvDirNames {
            let candidate = dir.appendingPathComponent(name)
            if await analyseVenv(at: candidate) != nil {
                return candidate
            }
        }
        return nil
    }

    // MARK: - Venv Analysis

    private func analyseVenv(at url: URL) async -> VenvInfo? {
        guard await fileHelper.exists(at: url) else { return nil }

        let pyvenvCfg = url.appendingPathComponent("pyvenv.cfg")
        guard let raw = await fileHelper.readTextFile(at: pyvenvCfg) else { return nil }

        let cfg = parsePyvenvCfg(raw)

        let isWindows = await fileHelper.exists(at: url.appendingPathComponent("Scripts/python.exe"))
        let hasBin = await fileHelper.exists(at: url.appendingPathComponent("bin/python"))
        let hasBin3 = await fileHelper.exists(at: url.appendingPathComponent("bin/python3"))
        let hasUnixPython = hasBin || hasBin3

        guard isWindows || hasUnixPython else { return nil }

        let version = cfg["version"] ?? cfg["version_info"] ?? "unknown"
        let home = cfg["home"] ?? "unknown"

        let packages = await scanInstalledPackages(at: url, version: version)
        let venvName = url.lastPathComponent

        return VenvInfo(
            pythonVersion: version,
            pythonHome: home,
            packages: packages,
            isWindows: isWindows,
            venvName: venvName
        )
    }

    private func parsePyvenvCfg(_ raw: String) -> [String: String] {
        var cfg: [String: String] = [:]
        for line in raw.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let val = parts[1].trimmingCharacters(in: .whitespaces)
            cfg[key] = val
        }
        return cfg
    }

    private func scanInstalledPackages(at venvDir: URL, version: String) async -> [String] {
        let libDir = venvDir.appendingPathComponent("lib")
        guard await fileHelper.isDirectory(at: libDir) else { return [] }

        let pythonDirs = await fileHelper.listDirectories(at: libDir)
        var sitePkgs: URL?
        for dir in pythonDirs where dir.lastPathComponent.hasPrefix("python") {
            let candidate = dir.appendingPathComponent("site-packages")
            if await fileHelper.isDirectory(at: candidate) {
                sitePkgs = candidate
                break
            }
        }

        guard let sitePkgs else { return [] }

        let entries = await fileHelper.listDirectories(at: sitePkgs)
        let skipSuffixes = [".dist-info", ".egg-info", ".pth"]
        let skipExact = ["__pycache__", "pip", "pip-", "setuptools", "wheel", "_distutils_hack"]

        return entries
            .map { $0.lastPathComponent }
            .filter { name in
                if skipExact.contains(name) || skipExact.contains(where: { name.hasPrefix($0) }) { return false }
                return !skipSuffixes.contains(where: { name.hasSuffix($0) })
            }
            .sorted()
    }

    // MARK: - Artifact Builder

    private func buildArtifact(venvDir: URL, info: VenvInfo, size: Int64, lastUsed: Date?, label: String) async -> DeveloperArtifact {
        let venvName = info.venvName
        let activateCmd = info.isWindows
            ? ".\\\(venvName)\\Scripts\\activate"
            : "source \(venvName)/bin/activate"
        let recreateCmd = info.isWindows
            ? "python -m venv \(venvName)"
            : "python3 -m venv \(venvName)"

        let explanation = """
        **\(label)** — Python \(info.pythonVersion)

        **Python:** \(info.pythonHome)

        **Activate:** `\(activateCmd)`
        **Recreate:** `\(recreateCmd)`
        """

        let rebuildEstimate: String
        if info.packages.isEmpty {
            rebuildEstimate = "Just recreate — no third-party deps"
        } else {
            rebuildEstimate = "Recreate + pip install \(info.packages.count) package(s)"
        }

        return await DeveloperArtifact(
            toolName: .venv,
            artifactType: "Virtual Environment",
            sizeBytes: size,
            safeToDelete: true,
            riskLevel: .slowRebuild,
            rebuildCostEstimate: rebuildEstimate,
            lastUsedDate: lastUsed,
            explanationText: explanation,
            underlyingPaths: [venvDir],
            installedPackages: info.packages.isEmpty ? [] : info.packages
        )
    }
}
