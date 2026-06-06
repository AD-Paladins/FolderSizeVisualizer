import XCTest

final class FolderSizeVisualizerUITests: XCTestCase {

    // Launches the app before each test
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    func testScanShowsResults() throws {
        let app = XCUIApplication()

        // Find the sidebar item or button that starts a scan
        let scanButton = app.buttons["Scan System"]
        XCTAssertTrue(scanButton.exists, "Scan System button should exist on launch")
        scanButton.tap()

        // Verify that scanning progress indicator appears
        let progress = app.progressIndicators.firstMatch
        XCTAssertTrue(progress.exists, "Progress indicator should appear while scanning")

        #if os(macOS)
        let cleanButton = app.buttons["Clean Safe Artifacts"]
        #else
        let cleanButton = app.buttons["Clean Safe Artifacts"]
        #endif

        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate, evaluatedWith: cleanButton, handler: nil)
        waitForExpectations(timeout: 30)

        XCTAssertTrue(cleanButton.exists, "Clean Safe Artifacts button should be present after scan completes")
    }
}