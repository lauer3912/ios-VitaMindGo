//
//  AppInfoTests.swift
//  VitaMindGo
//
//  Verify AppInfo reads correctly from Bundle.main.infoDictionary.
//  This guards against the old bug where Settings hardcoded "3.0.0" / "1"
//  while the actual build was 3.1.0 / 10 (commit 6c46b04).
//
//  Source of truth: project.yml → MARKETING_VERSION + CURRENT_PROJECT_VERSION
//  → xcodegen → xcodebuild → Info.plist → Bundle.main
//

import XCTest
@testable import VitaMindGo

final class AppInfoTests: XCTestCase {

    /// The appVersion must be a non-empty "X.Y.Z" string with at least one
    /// dot. It must NOT equal the legacy hardcoded "3.0.0" we removed.
    func testAppVersionIsSemVerAndNonEmpty() {
        let version = AppInfo.appVersion
        XCTAssertFalse(version.isEmpty, "appVersion should never be empty")
        XCTAssertTrue(version.contains("."),
                      "appVersion '\(version)' should be semver (X.Y.Z)")
        XCTAssertNotEqual(version, "0.0.0",
                          "appVersion should be populated from Info.plist, not fallback")
        XCTAssertNotEqual(version, "3.0.0",
                          "appVersion must not be the legacy hardcoded value")
    }

    /// Build number must be a non-empty positive integer string.
    func testBuildNumberIsPositiveInteger() {
        let build = AppInfo.buildNumber
        XCTAssertFalse(build.isEmpty, "buildNumber should never be empty")
        XCTAssertNotEqual(build, "0",
                          "buildNumber should be populated from Info.plist, not fallback")
        XCTAssertNotEqual(build, "1",
                          "buildNumber must not be the legacy hardcoded value")
        XCTAssertNotNil(Int(build),
                        "buildNumber '\(build)' must be parseable as Int")
        if let n = Int(build) {
            XCTAssertGreaterThan(n, 0, "buildNumber should be > 0")
        }
    }

    /// versionLine combines both, must include parens, must include build.
    func testVersionLineFormat() {
        let line = AppInfo.versionLine
        XCTAssertTrue(line.contains(AppInfo.appVersion),
                      "versionLine '\(line)' must include appVersion")
        XCTAssertTrue(line.contains(AppInfo.buildNumber),
                      "versionLine '\(line)' must include buildNumber")
        XCTAssertTrue(line.contains("(") && line.contains(")"),
                      "versionLine '\(line)' must use '(build)' format")
    }

    /// fullVersionLine is the verbose form for the About screen.
    func testFullVersionLineFormat() {
        let line = AppInfo.fullVersionLine
        XCTAssertTrue(line.contains("Version"),
                      "fullVersionLine '\(line)' must start with 'Version'")
        XCTAssertTrue(line.contains(AppInfo.appVersion))
        XCTAssertTrue(line.contains(AppInfo.buildNumber))
    }

    /// Regression guard: the hardcoded "3.0.0" + "1" pattern must never
    /// come back. If anyone re-hardcodes, this test catches it.
    func testNotLegacyHardcodedValues() {
        XCTAssertFalse(AppInfo.appVersion == "3.0.0" && AppInfo.buildNumber == "1",
                       "Detected legacy hardcoded values — must read from Bundle")
    }
}