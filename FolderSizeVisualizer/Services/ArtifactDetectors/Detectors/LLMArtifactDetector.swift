//
//  LLMArtifactDetector.swift
//  FolderSizeVisualizer
//
//  Detector for local LLM model caches (Ollama, HuggingFace, MLX, LM Studio)
//

import Foundation

actor LLMArtifactDetector: ArtifactDetector {
    nonisolated let tool: DeveloperTool = .localLLMs
    private let fileHelper = FileSystemHelper()

    func detect(progress: @Sendable @escaping (Double, String) async -> Void) async throws -> [DeveloperArtifact] {
        var artifacts: [DeveloperArtifact] = []

        await progress(0.2, "Scanning Ollama models...")
        let ollamaArtifacts = await detectOllama()
        artifacts.append(contentsOf: ollamaArtifacts)

        await progress(0.4, "Scanning HuggingFace cache...")
        let hfArtifacts = await detectHuggingFace()
        artifacts.append(contentsOf: hfArtifacts)

        await progress(0.6, "Scanning MLX models...")
        let mlxArtifacts = await detectMLX()
        artifacts.append(contentsOf: mlxArtifacts)

        await progress(0.8, "Scanning LM Studio models...")
        let lmStudioArtifacts = await detectLMStudio()
        artifacts.append(contentsOf: lmStudioArtifacts)

        await progress(0.9, "Scanning custom directories...")
        let customArtifacts = await detectCustomDirectories()
        artifacts.append(contentsOf: customArtifacts)

        await progress(1.0, "Completed LLM scan")

        return artifacts
    }

    func isToolInstalled() async -> Bool {
        let hasOllama = await fileHelper.exists(at: DeveloperPaths.ollamaModels)
        let hasHF = await fileHelper.exists(at: DeveloperPaths.huggingfaceCache)
        let hasMLX = await fileHelper.exists(at: DeveloperPaths.mlxModels)
        let hasLMStudio = await fileHelper.exists(at: DeveloperPaths.lmStudioModels)

        return hasOllama || hasHF || hasMLX || hasLMStudio
    }

    // MARK: - Ollama Detection

    private func detectOllama() async -> [DeveloperArtifact] {
        let modelsPath = DeveloperPaths.ollamaModels

        guard await fileHelper.exists(at: modelsPath) else {
            return []
        }

        let dirs = await fileHelper.listDirectories(at: modelsPath)
        var artifacts: [DeveloperArtifact] = []

        for modelDir in dirs {
            let size = await fileHelper.directorySize(at: modelDir)
            let lastUsed = await fileHelper.lastAccessDate(at: modelDir)
            let modelName = modelDir.lastPathComponent

            let artifact = await DeveloperArtifact(
                toolName: .localLLMs,
                artifactType: "Ollama Model",
                sizeBytes: size,
                safeToDelete: true,
                riskLevel: .slowRebuild,
                rebuildCostEstimate: "Re-pull from Ollama registry",
                lastUsedDate: lastUsed,
                explanationText: "Ollama model: **\(modelName)**\n\nStored in ~/.ollama/models. Safe to delete - models can be re-pulled with `ollama pull \(modelName)`.",
                underlyingPaths: [modelDir]
            )

            artifacts.append(artifact)
        }

        return artifacts
    }

    // MARK: - HuggingFace Detection

    private func detectHuggingFace() async -> [DeveloperArtifact] {
        let cachePath = DeveloperPaths.huggingfaceCache

        guard await fileHelper.exists(at: cachePath) else {
            return []
        }

        let dirs = await fileHelper.listDirectories(at: cachePath)
        var artifacts: [DeveloperArtifact] = []

        for categoryDir in dirs {
            let categoryName = categoryDir.lastPathComponent
            let categorySize = await fileHelper.directorySize(at: categoryDir)
            let lastUsed = await fileHelper.lastAccessDate(at: categoryDir)

            let artifact = await DeveloperArtifact(
                toolName: .localLLMs,
                artifactType: "HuggingFace Cache",
                sizeBytes: categorySize,
                safeToDelete: true,
                riskLevel: .slowRebuild,
                rebuildCostEstimate: "Re-download from HuggingFace",
                lastUsedDate: lastUsed,
                explanationText: "HuggingFace models cache: **\(categoryName)**\n\nStored in ~/.cache/huggingface. Safe to delete - models will be re-downloaded when needed.",
                underlyingPaths: [categoryDir]
            )

            artifacts.append(artifact)
        }

        return artifacts
    }

    // MARK: - MLX Detection

    private func detectMLX() async -> [DeveloperArtifact] {
        let cachePath = DeveloperPaths.mlxModels

        guard await fileHelper.exists(at: cachePath) else {
            return []
        }

        let dirs = await fileHelper.listDirectories(at: cachePath)
        var artifacts: [DeveloperArtifact] = []

        for modelDir in dirs {
            let size = await fileHelper.directorySize(at: modelDir)
            let lastUsed = await fileHelper.lastAccessDate(at: modelDir)
            let modelName = modelDir.lastPathComponent

            let artifact = await DeveloperArtifact(
                toolName: .localLLMs,
                artifactType: "MLX Model",
                sizeBytes: size,
                safeToDelete: true,
                riskLevel: .slowRebuild,
                rebuildCostEstimate: "Re-download Apple MLX model",
                lastUsedDate: lastUsed,
                explanationText: "Apple MLX optimized model: **\(modelName)**\n\nStored in ~/.cache/mlx. Safe to delete - models can be re-downloaded for Apple Silicon optimization.",
                underlyingPaths: [modelDir]
            )

            artifacts.append(artifact)
        }

        return artifacts
    }

    // MARK: - LM Studio Detection

    private func detectLMStudio() async -> [DeveloperArtifact] {
        let modelsPath = DeveloperPaths.lmStudioModels

        guard await fileHelper.exists(at: modelsPath) else {
            return []
        }

        let dirs = await fileHelper.listDirectories(at: modelsPath)
        var artifacts: [DeveloperArtifact] = []

        for modelDir in dirs {
            let size = await fileHelper.directorySize(at: modelDir)
            let lastUsed = await fileHelper.lastAccessDate(at: modelDir)
            let modelName = modelDir.lastPathComponent

            let artifact = await DeveloperArtifact(
                toolName: .localLLMs,
                artifactType: "LM Studio Model",
                sizeBytes: size,
                safeToDelete: true,
                riskLevel: .slowRebuild,
                rebuildCostEstimate: "Re-download from LM Studio",
                lastUsedDate: lastUsed,
                explanationText: "LM Studio model: **\(modelName)**\n\nStored in ~/.lm-studio/models. Safe to delete - models can be re-downloaded within LM Studio.",
                underlyingPaths: [modelDir]
            )

            artifacts.append(artifact)
        }

        return artifacts
    }

    // MARK: - Custom Directory Detection

    private func detectCustomDirectories() async -> [DeveloperArtifact] {
        guard let customDir = await fileHelper.resolveBookmark(for: .llmCustomDirectories) else {
            return []
        }

        let dirs = await fileHelper.listDirectories(at: customDir)
        var artifacts: [DeveloperArtifact] = []

        for modelDir in dirs {
            let size = await fileHelper.directorySize(at: modelDir)
            let lastUsed = await fileHelper.lastAccessDate(at: modelDir)
            let modelName = modelDir.lastPathComponent

            let artifact = await DeveloperArtifact(
                toolName: .localLLMs,
                artifactType: "Custom LLM",
                sizeBytes: size,
                safeToDelete: true,
                riskLevel: .slowRebuild,
                rebuildCostEstimate: "Re-download or restore from backup",
                lastUsedDate: lastUsed,
                explanationText: "Custom LLM directory: **\(modelName)**\n\nStored in a user-selected location. Safe to delete if you have a backup or can re-download.",
                underlyingPaths: [modelDir]
            )

            artifacts.append(artifact)
        }

        return artifacts
    }
}
