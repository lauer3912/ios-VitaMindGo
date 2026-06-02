import UIKit

final class AppIconLoader {
    static let shared = AppIconLoader()

    private(set) var iconImage: UIImage?

    private init() {
        iconImage = loadIcon()
    }

    private func loadIcon() -> UIImage? {
        // Method 1: Read CFBundleIcons from Info.plist (authoritative source)
        if let img = loadIconFromInfoPlist() {
            return img
        }

        // Method 2: Look for the largest AppIcon*.png in the bundle root
        if let img = loadIconFromBundleRoot() {
            return img
        }

        return nil
    }

    private func loadIconFromInfoPlist() -> UIImage? {
        let candidates: [String] = [
            "CFBundleIcons",
            "CFBundleIcons~ipad"
        ]

        for key in candidates {
            guard let icons = Bundle.main.object(forInfoDictionaryKey: key) as? [String: Any] else { continue }
            guard let primary = icons["CFBundlePrimaryIcon"] as? [String: Any] else { continue }
            guard let files = primary["CFBundleIconFiles"] as? [String] else { continue }

            // Try each filename, picking the highest resolution (@3x first, then @2x, then 1x)
            let sorted = files.sorted { lhs, rhs in
                let lScale = scaleRank(for: lhs)
                let rScale = scaleRank(for: rhs)
                return lScale > rScale
            }
            for name in sorted {
                if let img = UIImage(named: name) {
                    return img
                }
            }
        }
        return nil
    }

    private func scaleRank(for filename: String) -> Int {
        if filename.contains("@3x") { return 3 }
        if filename.contains("@2x") { return 2 }
        return 1
    }

    private func loadIconFromBundleRoot() -> UIImage? {
        // iOS copies the canonical AppIcon PNGs to the bundle root during build:
        //   AppIcon60x60@2x.png  (iPhone)
        //   AppIcon76x76@2x~ipad.png  (iPad)
        // Pick the largest available one.
        let candidates: [String] = [
            "AppIcon60x60@3x",
            "AppIcon60x60@2x",
            "AppIcon76x76@2x~ipad",
            "AppIcon76x76@1x~ipad",
            "AppIcon"
        ]

        let bundlePath = Bundle.main.bundlePath
        for name in candidates {
            for ext in ["png", "jpg"] {
                let path = "\(bundlePath)/\(name).\(ext)"
                if let img = UIImage(contentsOfFile: path) {
                    return img
                }
            }
            if let img = UIImage(named: name) {
                return img
            }
        }
        return nil
    }
}
