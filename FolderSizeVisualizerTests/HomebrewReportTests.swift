//
//  HomebrewReportTests.swift
//  FolderSizeVisualizerTests
//
//  Tests for the Homebrew dependency report generation and parsing.
//

import Foundation
import Testing

@testable import FolderSizeVisualizer

@Suite("Homebrew Dependency Report")
@MainActor
struct HomebrewReportTests {

    private let detector = HomebrewArtifactDetector()

    @Test("parseFormulaOutput handles name + version lines")
    func parseFormulaOutputWithVersions() async {
        let output = "git 2.39.3\njq 1.7\ntap 4.0.1\n"
        let deps = await detector.parseFormulaOutput(Data(output.utf8))

        #expect(deps.count == 3)
        #expect(deps.first?.name == "git")
        #expect(deps.first?.version == "2.39.3")
        #expect(deps[1].name == "jq")
        #expect(deps[2].name == "tap")
    }

    @Test("parseCaskOutput handles single-name lines")
    func parseCaskOutput() async {
        let output = "firefox\ndocker\nvisual-studio-code\n"
        let deps = await detector.parseCaskOutput(Data(output.utf8))

        #expect(deps.count == 3)
        #expect(deps.allSatisfy { $0.kind == .cask })
        #expect(deps.first?.name == "firefox")
    }

    @Test("generateDependencyReport returns a report when brew is available")
    func generateDependencyReport() async throws {
        let report = await detector.generateDependencyReport()

        #expect(report != nil)
        if let report {
            print("[INFO] Homebrew report: \(report.formulas.count) formulas, \(report.casks.count) casks")
        }
    }
}
