//
//  AppInfo.swift
//  VitaMindGo
//
//  Single source of truth for app metadata shown in Settings → App Info
//  and About. Reads from Bundle.main.infoDictionary so it always matches
//  the build that was actually compiled (no more drift between hardcoded
//  strings and project.yml MARKETING_VERSION / CURRENT_PROJECT_VERSION).
//
//  The build pipeline injects CFBundleShortVersionString and
//  CFBundleVersion from project.yml (xcodegen → xcodebuild archive).
//
//  Source of truth chain:
//    project.yml → xcodegen → xcodebuild → Info.plist → Bundle.main
//

import Foundation

enum AppInfo {

    /// Marketing version, e.g. "3.1.0". Maps to CFBundleShortVersionString.
    /// Falls back to "0.0.0" if Bundle is unreadable (should never happen
    /// in production but keeps the UI from crashing in edge cases like
    /// unit-test bundle loading).
    static let appVersion: String = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "0.0.0" : trimmed
    }()

    /// Build number, e.g. "10". Maps to CFBundleVersion.
    /// Falls back to "0" if Bundle is unreadable.
    static let buildNumber: String = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "0" : trimmed
    }()

    /// Combined "3.1.0 (10)" for compact display in headers / About.
    static let versionLine: String = "\(appVersion) (\(buildNumber))"

    /// Full descriptive line for About screen.
    static let fullVersionLine: String = "Version \(appVersion) (build \(buildNumber))"
}