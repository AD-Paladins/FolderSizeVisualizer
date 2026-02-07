//
//  DeveloperArtifact.swift
//  FolderSizeVisualizer
//
//  Domain model for developer tool artifacts
//

import Foundation

// MARK: - Risk Level

/// Indicates the safety and impact level of deleting an artifact
enum ArtifactRiskLevel: String, Codable, Sendable {
    case safe           // No rebuild needed, safe to delete anytime
    case slowRebuild    // Will trigger rebuild/redownload (time cost)
    case unsafe         // May break workflows or lose data
    case unknown        // Unable to determine safety
    
    var displayName: String {
        switch self {
        case .safe: return "Safe"
        case .slowRebuild: return "Slow Rebuild"
        case .unsafe: return "Unsafe"
        case .unknown: return "Unknown"
        }
    }
    
    var systemImage: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .slowRebuild: return "clock.arrow.circlepath"
        case .unsafe: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Developer Tool

/// Represents a developer tool or framework
enum DeveloperTool: String, Codable, CaseIterable, Identifiable, Sendable {
    case xcode
    case iosSimulator
    case androidStudio
    case androidSDK
    case docker
    case nodeJS
    case homebrew
    case python
    case rust
    case git
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .xcode: return "Xcode"
        case .iosSimulator: return "iOS Simulators"
        case .androidStudio: return "Android Studio"
        case .androidSDK: return "Android SDK"
        case .docker: return "Docker"
        case .nodeJS: return "Node.js"
        case .homebrew: return "Homebrew"
        case .python: return "Python"
        case .rust: return "Rust"
        case .git: return "Git"
        }
    }
    
    var systemImage: String {
        switch self {
        case .xcode: return "hammer.fill"
        case .iosSimulator: return "iphone"
        case .androidStudio: return "smartphone"
        case .androidSDK: return "sdk"
        case .docker: return "shippingbox.fill"
        case .nodeJS: return "square.stack.3d.up.fill"
        case .homebrew: return "mug.fill"
        case .python: return "terminal.fill"
        case .rust: return "gearshape.2.fill"
        case .git: return "arrow.triangle.branch"
        }
    }
}

// MARK: - Developer Artifact

/// Represents a single artifact created by a developer tool
struct DeveloperArtifact: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let toolName: DeveloperTool
    let artifactType: String
    let sizeBytes: Int64
    let safeToDelete: Bool
    let riskLevel: ArtifactRiskLevel
    let rebuildCostEstimate: String
    let lastUsedDate: Date?
    let explanationText: String
    let underlyingPaths: [URL]
    
    init(
        id: UUID = UUID(),
        toolName: DeveloperTool,
        artifactType: String,
        sizeBytes: Int64,
        safeToDelete: Bool,
        riskLevel: ArtifactRiskLevel,
        rebuildCostEstimate: String,
        lastUsedDate: Date? = nil,
        explanationText: String,
        underlyingPaths: [URL]
    ) {
        self.id = id
        self.toolName = toolName
        self.artifactType = artifactType
        self.sizeBytes = sizeBytes
        self.safeToDelete = safeToDelete
        self.riskLevel = riskLevel
        self.rebuildCostEstimate = rebuildCostEstimate
        self.lastUsedDate = lastUsedDate
        self.explanationText = explanationText
        self.underlyingPaths = underlyingPaths
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
    
    var lastUsedDescription: String {
        guard let date = lastUsedDate else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DeveloperArtifact, rhs: DeveloperArtifact) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tool Summary

/// Summary of all artifacts for a single tool
struct ToolArtifactSummary: Identifiable, Sendable {
    let id: UUID
    let tool: DeveloperTool
    let totalSize: Int64
    let totalArtifacts: Int
    let safeToDeleteSize: Int64
    let safeToDeleteCount: Int
    let artifacts: [DeveloperArtifact]
    
    init(tool: DeveloperTool, artifacts: [DeveloperArtifact]) {
        self.id = UUID()
        self.tool = tool
        self.artifacts = artifacts
        self.totalSize = artifacts.reduce(0) { $0 + $1.sizeBytes }
        self.totalArtifacts = artifacts.count
        
        let safeDeletable = artifacts.filter { $0.safeToDelete }
        self.safeToDeleteSize = safeDeletable.reduce(0) { $0 + $1.sizeBytes }
        self.safeToDeleteCount = safeDeletable.count
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedSafeToDeleteSize: String {
        ByteCountFormatter.string(fromByteCount: safeToDeleteSize, countStyle: .file)
    }
}
