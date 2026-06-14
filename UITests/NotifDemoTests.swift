import XCTest

/// Demo-mode UI test: walks through the full notification flow with
/// longer pauses so the recording captures each step clearly.
///
/// Run with:
///   xcrun simctl io <device> recordVideo --codec h264 out.mp4 &
///   xcodebuild test -project VitaPocket.xcodeproj -scheme VitaPocket \
///                  -only-testing:VitaPocketUITests/NotifDemoTests/testNotificationFlow
///   kill %1   # stop recording
final class NotifDemoTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testNotificationFlow() throws {
        let app = XCUIApplication()
        // --uitesting clears the persisted pull state so we can demo
        // the card animation later; does not affect notification flow.
        app.launchArguments += ["--uitesting"]

        // 1) Launch & wait — system permission alert should pop
        app.launch()
        sleep(3)  // hold on the alert so the recording catches it

        // 2) Tap Allow on the permission alert (system alert, not in app.alerts
        //    because XCUITest treats it as a UI interruption)
        let allow = app.alerts.buttons["Allow"]
        if allow.waitForExistence(timeout: 3) {
            allow.tap()
        }
        sleep(2)  // post-allow breathing room

        // 3) Navigate to Settings tab (5th tab, far right)
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.waitForExistence(timeout: 3) {
            settingsTab.tap()
        }
        sleep(2)

        // 4) Stay on top of Settings — the Notifications section is
        //    visible by default. (No swipe — swiping would push the
        //    "Send Test Notification" button off-screen.)
        sleep(2)

        // 5) Tap "Send Test Notification" — this fires a 1-second-delayed
        //    UNTimeIntervalNotificationTrigger. The banner then slides in
        //    from the top.
        let testBtn = app.buttons["Send Test Notification"]
        if testBtn.waitForExistence(timeout: 3) {
            testBtn.tap()
        }
        sleep(6)  // banner takes ~1s to appear + ~5s visible
    }
}
