//
//  HomebrewDependency.swift
//  FolderSizeVisualizer
//
//  Model for a single Homebrew-installed dependency (formula or cask).
//

import Foundation

/// A single dependency reported by `brew list --formula` / `brew list --cask`.
struct HomebrewDependency: Identifiable, Hashable, Sendable {
    /// Stable id derived from name + type so two packages never collide.
    let id: UUID = UUID()

    /// Package name (e.g. `git`, `docker`).
    let name: String

    /// Installed version / tag. Empty for casks.
    let version: String?

    /// Whether this is a Homebrew formula (source-compiled) or a cask (GUI app).
    let kind: Kind

    enum Kind: String, Sendable {
        case formula
        case cask
    }

    nonisolated init(name: String, version: String?, kind: Kind) {
        self.name = name
        self.version = version
        self.kind = kind
    }

    /// Human-readable label, e.g. `git 2.39.3`.
    var displayName: String {
        switch kind {
        case .formula:
            return version.map { "\($0)" } ?? name
        case .cask:
            return name
        }
    }
}

/// Aggregated report of every Homebrew dependency installed on the machine.
struct HomebrewDependencyReport: Sendable {
    let generatedAt: Date
    let formulas: [HomebrewDependency]
    let casks: [HomebrewDependency]

    var total: Int { formulas.count + casks.count }
    var formulaNames: [String] { formulas.map(\.name) }
    var caskNames: [String] { casks.map(\.name) }

    nonisolated init(generatedAt: Date, formulas: [HomebrewDependency], casks: [HomebrewDependency]) {
        self.generatedAt = generatedAt
        self.formulas = formulas.sorted { $0.name < $1.name }
        self.casks = casks.sorted { $0.name < $1.name }
    }
}
