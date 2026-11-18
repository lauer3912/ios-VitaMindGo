import Foundation
import Security

/// 极简 Keychain 封装：只用于存放本 App 需要的少量凭据（免费 AI Key、设备标识）。
///
/// 不使用 UserDefaults 存 Key：UserDefaults 以明文写入 App 沙盒备份，
/// Keychain 在设备锁定时不可读，且不随 iCloud 备份明文迁移。
enum KeychainStore {
    enum KeychainError: LocalizedError {
        case unexpectedStatus(OSStatus)
        case invalidValue

        var errorDescription: String? {
            switch self {
            case .unexpectedStatus(let status):
                return "Keychain 操作失败 (OSStatus \(status))"
            case .invalidValue:
                return "Keychain 写入的值无效"
            }
        }
    }

    private static var service: String {
        Bundle.main.bundleIdentifier ?? "com.techidaily.vita"
    }

    static func set(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.invalidValue }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        // 先删后写，保证覆盖写入不会残留旧值
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    static func string(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    static func remove(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
