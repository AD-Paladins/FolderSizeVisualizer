import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Result Model
struct RawAIResponse: Codable {
    let enhancedDescription: String
    let risk: String
    let reason: String
    let suggestedAction: String
    let documentationLinks: [DocLink]?
}
struct DocLink: Codable, Identifiable {
    let title: String
    let url: String
    var id: String { url }
}

struct ToolIntelligenceResult: Identifiable, Sendable, Codable {
    enum SuggestedAction: String, Codable, Sendable { case delete, keep, review }

    let id: UUID
    let tool: DeveloperTool
    let enhancedDescription: String
    let riskLevel: ArtifactRiskLevel
    let reason: String
    let suggestedAction: SuggestedAction
    let documentationLinks: [DocLink]
    
    init(
        id: UUID = UUID(),
        tool: DeveloperTool,
        enhancedDescription: String,
        riskLevel: ArtifactRiskLevel,
        reason: String,
        suggestedAction: SuggestedAction,
        documentationLinks: [DocLink]
    ) {
        self.id = id
        self.tool = tool
        self.enhancedDescription = enhancedDescription
        self.riskLevel = riskLevel
        self.reason = reason
        self.suggestedAction = suggestedAction
        self.documentationLinks = documentationLinks
    }
}



// MARK: - Service
actor ToolIntelligenceService: ToolIntelligenceProvider {
    enum Availability: Sendable, Equatable {
        case available
        case unavailable(String)
    }

    // Check if Apple Intelligence is available on this device/session
    func availability() async -> Availability {
        #if canImport(FoundationModels)
        guard #available(macOS 26.0, *) else {
            return .unavailable("Model unavailable for lower MacOS versions")
        }
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable("Model unavailable: \(await reason.friendlyString)")
        @unknown default:
            return .unavailable("Model unavailable for unknown reasons")
        }
        #else
        return .unavailable("FoundationModels framework not available on this platform/SDK")
        #endif
    }

    // Perform analysis for a tool using its summary. Throws if the model isn't available or another error occurs.
    func analyze(tool: DeveloperTool, summary: ToolArtifactSummary) async throws -> ToolIntelligenceResult {
        guard #available(macOS 26.0, *) else {
            throw NSError(domain: "ToolIntelligenceService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Apple Intelligence not available on this device/session"])
        }
        
        #if canImport(FoundationModels)
        guard case .available = await availability() else {
            throw NSError(domain: "ToolIntelligenceService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Apple Intelligence not available on this device/session"]) }

        let instructions = """
        You are a developer tools cleanup advisor. Your job is to:
        1) Provide a concise, accurate description of the developer tool and what kinds of disk artifacts it produces.
        2) Assess deletion risk using EXACTLY one of these labels: safe, slowRebuild, unsafe, unknown.
        3) Provide a brief reason for the risk.
        4) Suggest an action using EXACTLY one of: delete, keep, review.

        Respond ONLY with compact JSON using this schema:
        {
          "enhancedDescription": String,       // 2-4 sentences, markdown allowed
          "risk": "safe"|"slowRebuild"|"unsafe"|"unknown",
          "reason": String,                   // short justification
          "suggestedAction": "delete"|"keep"|"review",
          "documentationLinks": [
            { "title": String, "url": String }
          ]
        }
        No extra commentary, code fences, or explanations.
        """

        // Summarize artifacts (top 5 by size for context)
        let topArtifacts = summary.artifacts.sorted { $0.sizeBytes > $1.sizeBytes }.prefix(5)
        let artifactsList = topArtifacts.map { a in
            "- \(a.artifactType) — size: \(ByteCountFormatter.string(fromByteCount: a.sizeBytes, countStyle: .file)), safe: \(a.safeToDelete ? "yes" : "no"), risk: \(a.riskLevel.rawValue)"
        }.joined(separator: "\n")

        let prompt = """
        Tool name: \(await tool.displayName)
        Total artifacts: \(summary.totalArtifacts)
        Total size: \(await summary.formattedTotalSize)
        Safe-to-delete artifacts: \(summary.safeToDeleteCount) totaling \(await summary.formattedSafeToDeleteSize)
        Representative artifacts:\n\(artifactsList)
        """

        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt)
        let raw = response.content

        // Extract first JSON object from the response (be defensive)
        let jsonString: String
        if let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") , start <= end {
            jsonString = String(raw[start...end])
        } else {
            jsonString = raw
        }
        struct RawAIResponse: Codable {
            let enhancedDescription: String
            let risk: String
            let reason: String
            let suggestedAction: String
            let documentationLinks: [DocLink]?
            
            var docLinks: [FolderSizeVisualizer.DocLink] {
                guard let docs = documentationLinks else { return [] }
                return docs.compactMap { docLink in
                    FolderSizeVisualizer.DocLink(title: docLink.title, url: docLink.url)
                }
            }
        }
        struct DocLink: Codable {
            let title: String
            let url: String
        }
        
        let data = Data(jsonString.utf8)
        let decoded: RawAIResponse
        do {
            decoded = try JSONDecoder().decode(RawAIResponse.self, from: data)
        } catch {
            // Fallback: treat raw as description
            return await ToolIntelligenceResult(
                tool: tool,
                enhancedDescription: raw.trimmingCharacters(in: .whitespacesAndNewlines),
                riskLevel: .unknown,
                reason: "Could not parse structured response",
                suggestedAction: .review,
                documentationLinks: []
            )
        }

        let riskLevel: ArtifactRiskLevel
        switch decoded.risk.lowercased() {
        case "safe": riskLevel = .safe
        case "slowrebuild", "slow_rebuild", "rebuild", "moderate": riskLevel = .slowRebuild
        case "unsafe", "danger": riskLevel = .unsafe
        default: riskLevel = .unknown
        }

        let action: ToolIntelligenceResult.SuggestedAction
        switch decoded.suggestedAction.lowercased() {
        case "delete", "clean": action = .delete
        case "keep", "retain": action = .keep
        default: action = .review
        }

        return await ToolIntelligenceResult(
            tool: tool,
            enhancedDescription: decoded.enhancedDescription,
            riskLevel: riskLevel,
            reason: decoded.reason,
            suggestedAction: action,
            documentationLinks: decoded.docLinks
        )
        #else
        throw NSError(domain: "ToolIntelligenceService", code: 2, userInfo: [NSLocalizedDescriptionKey: "FoundationModels not available in this build"])        
        #endif
    }
}

// MARK: - Protocol
protocol ToolIntelligenceProvider {
    func availability() async -> ToolIntelligenceService.Availability
    func analyze(tool: DeveloperTool, summary: ToolArtifactSummary) async throws -> ToolIntelligenceResult
}
