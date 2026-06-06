import XCTest

/// Comprehensive integration tests for the scanning workflow introduced in IntegrationScannerUITests.swift.
///
/// These tests cover the full scanning lifecycle: warning banner dismissal, developer-mode
/// activation, scan initiation, progress indicator visibility, cancel behaviour, and the
/// resulting post-scan UI state.  They complement the single `testScanShowsResults` scenario
/// already present in IntegrationScannerUITests.swift.
final class ScannerIntegrationWorkflowTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        dismissWarningBannerIfPresent(in: app)
    }

    // MARK: - Helper: Warning Banner

    /// Taps the "Accept" button on the global deletion-warning overlay when it is present.
    /// The overlay is shown on first launch (or until "Don't show again" is checked).
    private func dismissWarningBannerIfPresent(in app: XCUIApplication) {
        let acceptButton = app.buttons["Accept"]
        if acceptButton.waitForExistence(timeout: 3) {
            acceptButton.tap()
        }
    }

    // MARK: - Warning Banner Tests

    /// The global warning overlay ("Accept" button) must appear when the app launches for the
    /// first time without the suppression flag set.
    @MainActor
    func testWarningBannerAcceptButtonExists() throws {
        // Re-launch so the banner is in its initial state for this test.
        let app = XCUIApplication()
        app.terminate()
        app.launch()

        let acceptButton = app.buttons["Accept"]
        XCTAssertTrue(
            acceptButton.waitForExistence(timeout: 5),
            "The 'Accept' button on the deletion-warning banner should exist on app launch"
        )
    }

    /// Tapping "Accept" on the warning banner must hide the overlay so that the underlying
    /// content (sidebar, toggles) becomes interactive.
    @MainActor
    func testAcceptButtonDismissesWarningBanner() throws {
        let app = XCUIApplication()
        app.terminate()
        app.launch()

        let acceptButton = app.buttons["Accept"]
        guard acceptButton.waitForExistence(timeout: 5) else {
            XCTFail("Accept button did not appear in time")
            return
        }
        acceptButton.tap()

        // After accepting, the banner should be gone.
        XCTAssertFalse(
            acceptButton.waitForExistence(timeout: 3),
            "Accept button should no longer be visible after it has been tapped"
        )
    }

    // MARK: - Standard-Mode Tests (no Scan System button)

    /// In standard (non-developer) mode the app shows ContentView, which contains a
    /// "Select Folder" button – not the "Scan System" button tested in IntegrationScannerUITests.
    /// Verifying that "Scan System" is absent guards against accidental UI regressions where
    /// the developer-mode view would be shown unconditionally.
    @MainActor
    func testScanSystemButtonAbsentInStandardMode() throws {
        let app = XCUIApplication()

        // Ensure the Developer-mode toggle is OFF (default).
        let devToggle = app.checkBoxes["Developer mode: "]
        if devToggle.exists && devToggle.value as? String == "1" {
            devToggle.click()
        }

        let scanSystemButton = app.buttons["Scan System"]
        // Wait briefly; the button must not appear in standard mode.
        XCTAssertFalse(
            scanSystemButton.waitForExistence(timeout: 2),
            "Scan System button must NOT be present when developer mode is disabled"
        )
    }

    // MARK: - Developer-Mode Activation Tests

    /// After the developer-mode toggle is switched on, the ArtifactContentView is displayed,
    /// which contains the "Scan System" button in ArtifactSidebarView.
    @MainActor
    func testDeveloperModeToggleRevealsScanSystemButton() throws {
        let app = XCUIApplication()

        let devToggle = app.checkBoxes["Developer mode: "]
        XCTAssertTrue(
            devToggle.waitForExistence(timeout: 5),
            "Developer mode toggle should be accessible without enabling developer mode"
        )
        // Switch to developer mode.
        devToggle.click()

        let scanSystemButton = app.buttons["Scan System"]
        XCTAssertTrue(
            scanSystemButton.waitForExistence(timeout: 5),
            "Scan System button must appear after enabling developer mode"
        )
    }

    // MARK: - Scan Initiation Tests

    /// Tapping "Scan System" should immediately display a progress indicator, confirming that
    /// the scan started and the UI reflects the `isScanning` state.
    @MainActor
    func testTappingScanSystemShowsProgressIndicator() throws {
        let app = XCUIApplication()

        // Enable developer mode to expose ArtifactSidebarView.
        let devToggle = app.checkBoxes["Developer mode: "]
        guard devToggle.waitForExistence(timeout: 5) else {
            XCTFail("Developer mode toggle not found")
            return
        }
        devToggle.click()

        let scanButton = app.buttons["Scan System"]
        guard scanButton.waitForExistence(timeout: 5) else {
            XCTFail("Scan System button not found after enabling developer mode")
            return
        }
        scanButton.tap()

        let progressIndicator = app.progressIndicators.firstMatch
        XCTAssertTrue(
            progressIndicator.waitForExistence(timeout: 5),
            "A progress indicator should appear immediately after tapping Scan System"
        )
    }

    /// While a scan is in progress the "Scan System" button must be disabled to prevent
    /// multiple concurrent scans from being initiated.
    @MainActor
    func testScanSystemButtonDisabledDuringActiveScan() throws {
        let app = XCUIApplication()

        let devToggle = app.checkBoxes["Developer mode: "]
        guard devToggle.waitForExistence(timeout: 5) else {
            XCTFail("Developer mode toggle not found")
            return
        }
        devToggle.click()

        let scanButton = app.buttons["Scan System"]
        guard scanButton.waitForExistence(timeout: 5) else {
            XCTFail("Scan System button not found")
            return
        }
        scanButton.tap()

        // The button should be disabled while the scan is running.
        XCTAssertFalse(
            scanButton.isEnabled,
            "Scan System button should be disabled while a scan is actively running"
        )
    }

    // MARK: - Cancel Scan Tests

    /// A "Cancel" button must appear in the sidebar while the scan is running, giving the
    /// user a way to abort the operation.
    @MainActor
    func testCancelButtonAppearsWhileScanning() throws {
        let app = XCUIApplication()

        let devToggle = app.checkBoxes["Developer mode: "]
        guard devToggle.waitForExistence(timeout: 5) else {
            XCTFail("Developer mode toggle not found")
            return
        }
        devToggle.click()

        let scanButton = app.buttons["Scan System"]
        guard scanButton.waitForExistence(timeout: 5) else {
            XCTFail("Scan System button not found")
            return
        }
        scanButton.tap()

        // "Cancel" button (ArtifactSidebarView) is rendered while `isScanning` is true.
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 5),
            "Cancel button should be visible in the sidebar while a scan is running"
        )
    }

    /// Tapping "Cancel" during a scan must stop the progress indicator, confirming that the
    /// scan task is cancelled and `isScanning` returns to false.
    @MainActor
    func testCancelButtonStopsProgressIndicator() throws {
        let app = XCUIApplication()

        let devToggle = app.checkBoxes["Developer mode: "]
        guard devToggle.waitForExistence(timeout: 5) else {
            XCTFail("Developer mode toggle not found")
            return
        }
        devToggle.click()

        let scanButton = app.buttons["Scan System"]
        guard scanButton.waitForExistence(timeout: 5) else {
            XCTFail("Scan System button not found")
            return
        }
        scanButton.tap()

        let cancelButton = app.buttons["Cancel"]
        guard cancelButton.waitForExistence(timeout: 5) else {
            XCTFail("Cancel button did not appear while scanning")
            return
        }
        cancelButton.tap()

        // After cancellation the progress indicator should disappear.
        let progressGone = NSPredicate(format: "exists == false")
        let progressIndicator = app.progressIndicators.firstMatch
        expectation(for: progressGone, evaluatedWith: progressIndicator, handler: nil)
        waitForExpectations(timeout: 10)

        XCTAssertFalse(
            progressIndicator.exists,
            "Progress indicator should no longer be visible after the scan is cancelled"
        )
    }

    // MARK: - Post-Scan State Tests

    /// After a completed scan the "Scan System" button should be re-enabled, allowing
    /// the user to initiate a subsequent scan.
    @MainActor
    func testScanSystemButtonReenabledAfterScanCompletes() throws {
        let app = XCUIApplication()

        let devToggle = app.checkBoxes["Developer mode: "]
        guard devToggle.waitForExistence(timeout: 5) else {
            XCTFail("Developer mode toggle not found")
            return
        }
        devToggle.click()

        let scanButton = app.buttons["Scan System"]
        guard scanButton.waitForExistence(timeout: 5) else {
            XCTFail("Scan System button not found")
            return
        }
        scanButton.tap()

        // Wait for the progress indicator to disappear (scan finished or no artifacts found).
        let progressIndicator = app.progressIndicators.firstMatch
        let progressGone = NSPredicate(format: "exists == false")
        expectation(for: progressGone, evaluatedWith: progressIndicator, handler: nil)
        waitForExpectations(timeout: 60)

        // Now that scanning is done the button must be enabled again.
        XCTAssertTrue(
            scanButton.isEnabled,
            "Scan System button should be re-enabled once scanning finishes"
        )
    }

    // MARK: - Regression / Boundary Tests

    /// Initiating a scan a second time immediately after the first completes must not leave
    /// a residual progress indicator or a disabled button, guarding against state-reset bugs.
    @MainActor
    func testSubsequentScanCanBeStartedAfterFirstScanCompletes() throws {
        let app = XCUIApplication()

        let devToggle = app.checkBoxes["Developer mode: "]
        guard devToggle.waitForExistence(timeout: 5) else {
            XCTFail("Developer mode toggle not found")
            return
        }
        devToggle.click()

        let scanButton = app.buttons["Scan System"]
        guard scanButton.waitForExistence(timeout: 5) else {
            XCTFail("Scan System button not found")
            return
        }

        // First scan.
        scanButton.tap()
        let progressIndicator = app.progressIndicators.firstMatch
        let progressGone = NSPredicate(format: "exists == false")
        expectation(for: progressGone, evaluatedWith: progressIndicator, handler: nil)
        waitForExpectations(timeout: 60)

        // Second scan – button should be enabled and tappable.
        XCTAssertTrue(scanButton.isEnabled, "Scan System button should be enabled for a second scan")
        scanButton.tap()

        // Progress indicator should reappear for the second scan.
        XCTAssertTrue(
            progressIndicator.waitForExistence(timeout: 5),
            "Progress indicator should appear when the second scan is initiated"
        )
    }
}
