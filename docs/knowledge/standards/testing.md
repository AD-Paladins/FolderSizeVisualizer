# Testing Standards

## Test Types

| Type | Framework | Location | What it covers |
|---|---|---|---|
| Unit | Swift Testing (`import Testing`) | `FolderSizeVisualizerTests/` | Models, services, ViewModels |
| UI | XCTest (`import XCTest`) | `FolderSizeVisualizerUITests/` | Critical user journeys, launch, integration |
| Snapshot | Not used | — | — |

This project uses **Swift Testing** (Apple's modern test framework) for unit tests and **XCTest** for UI tests. Do not use XCTest for unit tests.

## Naming Convention (Swift Testing)

```swift
@Test func subject_condition() {
    #expect(expression)
}
```

Swift Testing does not enforce naming conventions, but follow: `describe_condition()`.

## Unit Tests (Swift Testing)

- One test file per type under test: `XcodeArtifactDetectorTests.swift`
- Use `@Test` macros, not `XCTestCase` subclasses
- Use `#expect()` instead of `XCTAssertEqual`, `XCTAssertTrue`, etc.
- Use `await` for async test functions
- No `sleep()` or timing hacks
- Mock at the boundary using protocols

```swift
import Testing
@testable import FolderSizeVisualizer

@Test func venvDetector_installed_detectsVenvs() async {
    let detector = VenvArtifactDetector(fileHelper: .mock)
    let artifacts = try await detector.detect { _, _ in }
    #expect(artifacts.count > 0)
}
```

## UI Tests (XCTest)

- Use `XCUIApplication` for launch and interaction
- Test critical user journeys: scan, navigate, clean
- Include a launch performance test
- Keep UI tests in `FolderSizeVisualizerUITests/` (not in the test plan)

## What Not to Test

- SwiftUI `body` internals directly
- Third-party / system framework behavior
- `private` methods — test through public interface

## Coverage

The test plan (`FolderSizeVisualizerTests.xctestplan`) includes only unit tests, configured as parallelizable. UI tests must be run separately.

## Known Gaps

- `ArtifactScanViewModel` has no tests
- `ArtifactScanService` has no tests
- Most artifact detectors have no tests (only `VenvArtifactDetector` is tested)
- `DeveloperArtifact` model has no tests
