import XCTest

/// One-off: launch the app, accept the notification permission, and
/// capture the Pocket tab so we can document the no-mock empty state
/// for App Store review. The image is written next to the demo assets.
final class EmptyStateCaptureTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCapturePocketAfterRemovingMockData() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting"]

        // Pre-install an interruption monitor to auto-accept the
        // "Would Like to Send You Notifications" system alert
        addUIInterruptionMonitor(withDescription: "Notification Permission") { (alert) -> Bool in
            if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
                return true
            }
            return false
        }

        app.launch()
        app.swipeUp()  // trigger monitor
        sleep(1)
        app.tap()
        sleep(3)  // let the alert dismiss

        // Pocket tab is default-selected on launch — just screenshot
        let path = "/Users/user291981/Desktop/ios-VitaMind/docs/notifications/screenshots/06-pocket-no-mock.png"
        let shot = app.screenshot()
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: path))
        print("📸 \(path)")
    }
}
