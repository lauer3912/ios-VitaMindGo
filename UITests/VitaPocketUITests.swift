import XCTest

final class VitaPocketUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Enable Point Accurate mode for precise screenshots
        app.launchArguments = ["--uitesting", "-AppleContinuousContinuously"]
        app.launch()
        Thread.sleep(forTimeInterval: 3.0)
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - Screenshot Capture

    private func capture(_ name: String) {
        let path = "/tmp/\(name).png"
        let image = app.windows.firstMatch.screenshot()
        let data = image.pngRepresentation
        try? data.write(to: URL(fileURLWithPath: path))
        print("📸 Captured: \(path)")
        
        // Get file size for verification
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
           let size = attrs[.size] as? Int {
            print("   Size: \(size) bytes")
        }
    }

    private func tapTab(_ label: String) {
        let button = app.buttons[label]
        button.tap()
        Thread.sleep(forTimeInterval: 1.5)
        print("✓ Tapped tab: \(label)")
    }

    // MARK: - Test: All Tabs (iPhone 17 Pro Max)
    
    func testAllTabs() {
        print("=== iPhone 17 Pro Max - Capturing screenshots ===")
        
        // Tab 1: Pocket
        capture("vp_tab1_pocket")
        
        // Tab 2: Habits
        tapTab("Habits")
        capture("vp_tab2_habits")
        
        // Tab 3: Coach
        tapTab("Coach")
        capture("vp_tab3_coach")
        
        // Tab 4: Collection
        tapTab("Collection")
        capture("vp_tab4_collection")
        
        print("=== iPhone 17 Pro Max - All tabs captured ===")
        Thread.sleep(forTimeInterval: 2.0)
    }
}

// MARK: - iPad Pro 13-inch (M4) Tests

final class VitaPocketiPadTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        Thread.sleep(forTimeInterval: 3.0)
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    private func capture(_ name: String) {
        let path = "/tmp/\(name).png"
        let image = app.windows.firstMatch.screenshot()
        let data = image.pngRepresentation
        try? data.write(to: URL(fileURLWithPath: path))
        print("📸 Captured: \(path)")
    }

    private func tapTab(_ label: String) {
        let button = app.buttons[label]
        button.tap()
        Thread.sleep(forTimeInterval: 1.5)
        print("✓ Tapped tab: \(label)")
    }

    func testAllTabs() {
        print("=== iPad Pro 13-inch (M4) - Capturing screenshots ===")
        
        // Tab 1: Pocket
        capture("ipad_tab1_pocket")
        
        // Tab 2: Habits
        tapTab("Habits")
        capture("ipad_tab2_habits")
        
        // Tab 3: Coach
        tapTab("Coach")
        capture("ipad_tab3_coach")
        
        // Tab 4: Collection
        tapTab("Collection")
        capture("ipad_tab4_collection")
        
        print("=== iPad Pro 13-inch (M4) - All tabs captured ===")
        Thread.sleep(forTimeInterval: 2.0)
    }
}

// MARK: - Apple Watch Ultra 3 Tests

final class VitaPocketWatchTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        Thread.sleep(forTimeInterval: 2.0)
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    private func capture(_ name: String) {
        let path = "/tmp/\(name).png"
        // Watch apps have different UI hierarchy
        if let window = app.windows.firstMatch {
            let image = window.screenshot()
            let data = image.pngRepresentation
            try? data.write(to: URL(fileURLWithPath: path))
            print("📸 Captured: \(path)")
        }
    }

    func testMainView() {
        print("=== Apple Watch Ultra 3 - Capturing screenshot ===")
        capture("watch_tab1_main")
        print("=== Apple Watch Ultra 3 - Captured ===")
    }
}