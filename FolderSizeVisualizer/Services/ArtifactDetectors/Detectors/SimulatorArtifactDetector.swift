//
//  SimulatorArtifactDetector.swift
//  FolderSizeVisualizer
//
//  Detects iOS Simulator artifacts with runtime-aware management
//

import Foundation

// MARK: - Simulator Runtime Info

struct SimulatorRuntime: Codable, Sendable {
    let identifier: String
    let version: String
    let name: String
    let isAvailable: Bool
    
    var displayName: String {
        "\(name) \(version)"
    }
}

// MARK: - Simulator Device Info

struct SimulatorDevice: Codable, Sendable {
    let udid: String
    let name: String
    let state: String
    let runtime: String
    let dataPath: URL?
    let lastBootedAt: Date?
    let isAvailable: Bool
    
    var isRunning: Bool {
        state.lowercased() == "booted"
    }
}

// MARK: - Simulator Artifact Detector

actor SimulatorArtifactDetector: ArtifactDetector {
    nonisolated let tool: DeveloperTool = .iosSimulator
    private let fileHelper = FileSystemHelper()
    
    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []
        
        // Parse simulator data using simctl
        await progress(0.1, "Reading simulator configuration...")
        let devices = await parseSimulatorDevices()
        let runtimes = await parseSimulatorRuntimes()
        
        // Detect individual simulator devices
        await progress(0.3, "Analyzing simulator devices...")
        let deviceArtifacts = await detectSimulatorDevices(devices: devices, runtimes: runtimes)
        artifacts.append(contentsOf: deviceArtifacts)
        
        // Detect unavailable devices (safe to delete)
        await progress(0.6, "Checking unavailable devices...")
        let unavailableArtifacts = await detectUnavailableDevices(devices: devices)
        artifacts.append(contentsOf: unavailableArtifacts)
        
        // Detect simulator runtimes from system assets
        await progress(0.7, "Scanning simulator runtimes...")
        let runtimeArtifacts = await detectSimulatorRuntimes()
        artifacts.append(contentsOf: runtimeArtifacts)
        
        // Detect simulator caches
        await progress(0.8, "Scanning simulator caches...")
        let cacheArtifacts = await detectSimulatorCaches()
        artifacts.append(contentsOf: cacheArtifacts)
        
        await progress(1.0, "Completed simulator scan")
        
        return artifacts.sorted { $0.sizeBytes > $1.sizeBytes }
    }
    
    func isToolInstalled() async -> Bool {
        let path = await DeveloperPaths.simulators
        let exists = await fileHelper.exists(at: path)
        print("  🔍 Simulator path check: \(path.path) - exists: \(exists)")
        return exists
    }
    
    // MARK: - Parse Simulator Data
    
    private func parseSimulatorDevices() async -> [SimulatorDevice] {
        guard let result = await fileHelper.runProcess(
            launchPath: "/usr/bin/xcrun",
            arguments: ["simctl", "list", "devices", "-j"]
        ), let data = result.output else {
            return []
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devicesDict = json["devices"] as? [String: [[String: Any]]] else {
            return []
        }

        var devices: [SimulatorDevice] = []

        for (runtime, deviceList) in devicesDict {
            for deviceData in deviceList {
                guard let udid = deviceData["udid"] as? String,
                      let name = deviceData["name"] as? String,
                      let state = deviceData["state"] as? String else {
                    continue
                }

                let dataPathString = deviceData["dataPath"] as? String
                let dataPath = dataPathString.map { URL(fileURLWithPath: $0) }
                let isAvailable = deviceData["isAvailable"] as? Bool ?? true

                let device = SimulatorDevice(
                    udid: udid,
                    name: name,
                    state: state,
                    runtime: runtime,
                    dataPath: dataPath,
                    lastBootedAt: nil,
                    isAvailable: isAvailable
                )

                devices.append(device)
            }
        }

        return devices
    }
    
    private func parseSimulatorRuntimes() async -> [SimulatorRuntime] {
        guard let result = await fileHelper.runProcess(
            launchPath: "/usr/bin/xcrun",
            arguments: ["simctl", "list", "runtimes", "-j"]
        ), let data = result.output else {
            return []
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let runtimesList = json["runtimes"] as? [[String: Any]] else {
            return []
        }

        var runtimes: [SimulatorRuntime] = []

        for runtimeData in runtimesList {
            guard let identifier = runtimeData["identifier"] as? String,
                  let version = runtimeData["version"] as? String,
                  let name = runtimeData["name"] as? String else {
                continue
            }

            let isAvailable = runtimeData["isAvailable"] as? Bool ?? true

            let runtime = SimulatorRuntime(
                identifier: identifier,
                version: version,
                name: name,
                isAvailable: isAvailable
            )

            runtimes.append(runtime)
        }

        return runtimes
    }
    
    // MARK: - Device Detection
    
    private func detectSimulatorDevices(devices: [SimulatorDevice], runtimes: [SimulatorRuntime]) async -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []
        
        for device in devices {
            guard let dataPath = device.dataPath,
                  await fileHelper.exists(at: dataPath) else {
                continue
            }
            
            let size = await fileHelper.directorySize(at: dataPath)
            let lastUsed = await fileHelper.lastAccessDate(at: dataPath)
            
            let runtimeName = await runtimes.first(where: { device.runtime.contains($0.identifier) })?.displayName ?? device.runtime
            
            let safeToDelete = await !device.isRunning && device.isAvailable
            let riskLevel: ArtifactRiskLevel = await device.isRunning ? .unsafe : .safe
            
            let artifact = await DeveloperArtifact(
                toolName: .iosSimulator,
                artifactType: "Simulator Device",
                sizeBytes: size,
                safeToDelete: safeToDelete,
                riskLevel: riskLevel,
                rebuildCostEstimate: device.isRunning ? "Cannot delete while running" : "Recreate in seconds",
                lastUsedDate: lastUsed,
                explanationText: "\(device.name) (\(runtimeName)). Contains app data, settings, and files for this simulator. \(device.isRunning ? "Currently running - cannot delete." : "Safe to delete - recreate anytime.")",
                underlyingPaths: [dataPath]
            )
            
            artifacts.append(artifact)
        }
        
        return artifacts
    }
    
    // MARK: - Simulator Runtime Detection
    private func detectSimulatorRuntimes() async -> [DeveloperArtifact] {
        let baseURL = URL(fileURLWithPath: "/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime")
        var artifacts: [DeveloperArtifact] = []

        // Ensure the base path exists
        guard await fileHelper.exists(at: baseURL) else {
            return []
        }

        let fm = FileManager.default

        // List all subdirectories inside the base path
        let subitems: [URL]
        do {
            subitems = try fm.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        } catch {
            return []
        }

        for item in subitems {
            // Only consider directories
            let resourceValues = try? item.resourceValues(forKeys: [.isDirectoryKey])
            guard resourceValues?.isDirectory == true else { continue }

            // Find a plist file inside this directory (non-recursive)
            let plistURL: URL? = {
                let children = (try? fm.contentsOfDirectory(at: item, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
                return children.first(where: { $0.pathExtension.lowercased() == "plist" })
            }()

            guard let plistURL else { continue }

            // Parse plist to extract name/version when available
            var runtimeName: String = "iOS Simulator Runtime"
            var runtimeVersion: String = "Unknown"
            var buildVersion: String = "Unknown"
            var architectures: String = "Unknown"
            if let data = try? Data(contentsOf: plistURL),
               let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                if let name = (plist["Name"] as? String) ?? (plist["name"] as? String) {
                    runtimeName = name
                }
                if let mobileAssetProperties = plist["MobileAssetProperties"] as? [String:Any] {
                    let version = mobileAssetProperties["SimulatorVersion"] as? String ?? ""
                    let build = mobileAssetProperties["Build"] as? String
                    let archs = mobileAssetProperties["Architectures"] as? [String]
                    runtimeVersion = version
                    buildVersion = build ?? "Unknown"
                    architectures = archs?.joined(separator: ", ") ?? "Unknown"
                }
            }

            // Compute size and last access date for this runtime directory
            let size = await fileHelper.directorySize(at: item)
            let lastUsed = await fileHelper.lastAccessDate(at: item)

            let explanation = "\(runtimeName).\n**OS version:** \(runtimeVersion) (build \(buildVersion))\n **Architecture(s):** \(architectures)\nSystem-provided simulator runtime assets. Not recommended to delete."

            let artifact = await DeveloperArtifact(
                toolName: .iosSimulator,
                artifactType: "Simulator Runtime",
                sizeBytes: size,
                safeToDelete: false,
                riskLevel: .unsafe,
                rebuildCostEstimate: "System component — managed by the OS/Xcode\nNeeds to be downloaded again (9GB+).",
                lastUsedDate: lastUsed,
                explanationText: explanation,
                underlyingPaths: [item]
            )

            artifacts.append(artifact)
        }

        return artifacts
    }
    
    // MARK: - Unavailable Devices Detection
    
    private func detectUnavailableDevices(devices: [SimulatorDevice]) async -> [DeveloperArtifact] {
        let unavailableDevices = devices.filter { !$0.isAvailable }
        var artifacts: [DeveloperArtifact] = []
        
        for device in unavailableDevices {
            guard let dataPath = device.dataPath,
                  await fileHelper.exists(at: dataPath) else {
                continue
            }
            
            let size = await fileHelper.directorySize(at: dataPath)
            
            let artifact = await DeveloperArtifact(
                toolName: .iosSimulator,
                artifactType: "Unavailable Device",
                sizeBytes: size,
                safeToDelete: true,
                riskLevel: .safe,
                rebuildCostEstimate: "No rebuild needed",
                lastUsedDate: nil,
                explanationText: "\(device.name) is unavailable (runtime not installed or incompatible). Safe to delete.",
                underlyingPaths: [dataPath]
            )
            
            artifacts.append(artifact)
        }
        
        return artifacts
    }
    
    // MARK: - Cache Detection
    
    private func detectSimulatorCaches() async -> [DeveloperArtifact] {
        let cachePath = await DeveloperPaths.simulatorVolumes
        
        guard await fileHelper.exists(at: cachePath) else {
            return []
        }
        
        let size = await fileHelper.directorySize(at: cachePath)
        let lastUsed = await fileHelper.lastAccessDate(at: cachePath)
        
        let artifact = await DeveloperArtifact(
            toolName: .iosSimulator,
            artifactType: "Simulator Caches",
            sizeBytes: size,
            safeToDelete: true,
            riskLevel: .safe,
            rebuildCostEstimate: "Auto-regenerated as needed",
            lastUsedDate: lastUsed,
            explanationText: "Temporary files and caches used by the iOS Simulator. Safe to delete - automatically regenerated.",
            underlyingPaths: [cachePath]
        )
        
        return [artifact]
    }
}
