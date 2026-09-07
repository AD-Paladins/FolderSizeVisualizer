//
//  FileSystemHelperRunProcessTests.swift
//  FolderSizeVisualizerTests
//
//  Validates the timeout / termination behavior of FileSystemHelper.runProcess.
//

import Foundation
import Testing

@testable import FolderSizeVisualizer

@Suite("FileSystemHelper.runProcess Timeout Tests", .serialized)
struct FileSystemHelperRunProcessTests {

    private let helper = FileSystemHelper()

    /// Creates a shell script that sleeps for `seconds` then prints a token.
    private func makeSleepingScript(seconds: Int, label: String) throws -> URL {
        let fm = FileManager.default
        let url = fm.temporaryDirectory
            .appendingPathComponent("FSVRunProcess-\(UUID().uuidString)-\(label)", isDirectory: true)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)

        let script = """
        #!/bin/bash
        sleep $1
        echo "DONE-\(label)"
        """
        let scriptURL = url.appendingPathComponent("run.sh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o755)],
            ofItemAtPath: scriptURL.path
        )
        return scriptURL
    }

    @Test("returns output for a fast process")
    func returnsOutputForFastProcess() async throws {
        let script = try makeSleepingScript(seconds: 0, label: "fast")

        let start = DispatchTime.now().uptimeNanoseconds
        let result = await helper.runProcess(
            launchPath: "/bin/bash",
            arguments: [script.path, "0"],
            timeout: 5
        )
        let elapsedMs = (DispatchTime.now().uptimeNanoseconds - start) / 1_000_000

        #expect(result != nil)
        if let result {
            #expect(result.exitCode == 0)
            if let output = result.output {
                let text = String(data: output, encoding: .utf8)
                #expect(text == "DONE-fast\n")
            }
        }
        // Should complete well under the timeout window.
        #expect(elapsedMs < 4_000)
    }

    @Test("terminates a hung process at the timeout and returns nil")
    func terminatesHungProcessAtTimeout() async throws {
        let script = try makeSleepingScript(seconds: 30, label: "hung")

        let start = DispatchTime.now().uptimeNanoseconds
        let result = await helper.runProcess(
            launchPath: "/bin/bash",
            arguments: [script.path, "30"],
            timeout: 1
        )
        let elapsedMs = (DispatchTime.now().uptimeNanoseconds - start) / 1_000_000

        #expect(result == nil)
        // Should give up around the 1s timeout, not run for 30s.
        #expect(elapsedMs >= 900)
        #expect(elapsedMs < 8_000)
    }

    @Test("returns nil when the process cannot be launched")
    func returnsNilWhenLaunchFails() async throws {
        let result = await helper.runProcess(
            launchPath: "/nonexistent/binary/please",
            arguments: [],
            timeout: 5
        )
        #expect(result == nil)
    }
}
