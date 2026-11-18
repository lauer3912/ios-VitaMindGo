import Foundation

/// 免费 AI Key 管理：从 credits.techidaily.com 申领平台作用域的免费 Key。
///
/// 设计要点：
///  - App 拿到的不是上游厂商 Key，而是平台作用域 Key（`tdk_live_…`）。
///    上游 Key 永远不下发到设备，平台负责代理与计量，因此平台可以随时轮换上游 Key。
///  - Key 与设备标识都存在 Keychain，不写 UserDefaults、不写代码、不进包体。
///  - 免登录：额度按设备维度计量（平台侧日配额 + 总量封顶）。
actor FreeAIKeyManager {
    static let shared = FreeAIKeyManager()

    struct Quota: Codable, Equatable {
        let dailyQuota: Int
        let dailyUsed: Int
        let dailyRemaining: Int
        let totalQuota: Int
        let totalUsed: Int
        let totalRemaining: Int
    }

    struct Status: Equatable {
        let key: String
        let model: String
        let quota: Quota
    }

    enum FreeAIKeyError: LocalizedError {
        case platformUnavailable(String)
        case quotaExhausted
        case invalidResponse
        case unauthorized
        case rateLimited(retryAfter: Int?)

        var errorDescription: String? {
            switch self {
            case .platformUnavailable(let detail):
                return "AI service unavailable: \(detail)"
            case .quotaExhausted:
                return "Free AI quota exhausted. Please try again later."
            case .invalidResponse:
                return "AI service returned an unexpected response."
            case .unauthorized:
                return "Free AI key was rejected. Please reopen Settings to refresh it."
            case .rateLimited(let retryAfter):
                if let retryAfter {
                    return "Too many requests. Please retry in \(retryAfter)s."
                }
                return "Too many requests. Please retry later."
            }
        }
    }

    private struct IssueResponse: Decodable {
        let success: Bool
        let key: String
        let model: String
        let quota: Quota
    }

    private struct StatusResponse: Decodable {
        let success: Bool
        let model: String
        let quota: Quota
    }

    private struct ErrorResponse: Decodable {
        let success: Bool?
        let code: String?
        let error: String?
    }

    private let deviceIdKey = "free_ai_device_id"
    private let apiKeyKey = "free_ai_api_key"
    private var cached: Status?
    // Keychain 不可用时（例如未签名的测试构建）仍要保持设备标识与 Key 稳定，
    // 否则每次启动都会被当成新设备，撞上平台的单日发放上限。
    private var memoryDeviceId: String?
    private var memoryApiKey: String?

    /// 平台地址：默认生产域名；本地联调可用 CREDITS_PLATFORM_BASE_URL 环境变量覆盖。
    static func platformBaseURL() -> URL {
        if let override = ProcessInfo.processInfo.environment["CREDITS_PLATFORM_BASE_URL"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: override.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return url
        }
        if let configured = Bundle.main.object(forInfoDictionaryKey: "CreditsPlatformBaseURL") as? String,
           !configured.isEmpty,
           let url = URL(string: configured) {
            return url
        }
        return URL(string: "https://credits.techidaily.com")!
    }

    /// Anthropic 兼容代理端点（与平台 /api/ai/config 返回的 endpoint 一致）。
    static func messagesEndpoint() -> String {
        platformBaseURL().appendingPathComponent("api/ai/v1/messages").absoluteString
    }

    private var baseURL: URL {
        Self.platformBaseURL()
    }

    private var bundleId: String {
        Bundle.main.bundleIdentifier ?? "com.ggsheng.VitaMind"
    }

    private var operatingSystemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// 设备标识：首次调用时生成并写入 Keychain，作为平台侧额度计量与风控锚点。
    func deviceIdentifier() -> String {
        if let existing = KeychainStore.string(for: deviceIdKey), !existing.isEmpty {
            memoryDeviceId = existing
            return existing
        }
        if let cached = memoryDeviceId, !cached.isEmpty {
            return cached
        }
        let generated = UUID().uuidString.lowercased()
        memoryDeviceId = generated
        try? KeychainStore.set(generated, for: deviceIdKey)
        return generated
    }

    /// 当前可用 Key：优先内存缓存，其次 Keychain；都没有则向平台申领。
    func currentStatus(allowIssue: Bool = true) async throws -> Status {
        if let cached, !cached.key.isEmpty {
            return cached
        }
        if let stored = KeychainStore.string(for: apiKeyKey), !stored.isEmpty {
            memoryApiKey = stored
            let status = Status(key: stored, model: "MiniMax-M3", quota: Quota(
                dailyQuota: 0, dailyUsed: 0, dailyRemaining: 0,
                totalQuota: 0, totalUsed: 0, totalRemaining: 0
            ))
            cached = status
            return status
        }
        if let stored = memoryApiKey, !stored.isEmpty {
            let status = Status(key: stored, model: "MiniMax-M3", quota: Quota(
                dailyQuota: 0, dailyUsed: 0, dailyRemaining: 0,
                totalQuota: 0, totalUsed: 0, totalRemaining: 0
            ))
            cached = status
            return status
        }
        guard allowIssue else {
            throw FreeAIKeyError.platformUnavailable("no issued key")
        }
        return try await refresh()
    }

    /// 向平台申领（或重新取回）本设备的免费 Key。
    @discardableResult
    func refresh() async throws -> Status {
        let url = baseURL.appendingPathComponent("api/ai/keys")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(deviceIdentifier(), forHTTPHeaderField: "X-Device-Id")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "deviceKey": deviceIdentifier(),
            "bundleId": bundleId,
            "deviceName": ProcessInfo.processInfo.hostName,
            "osVersion": operatingSystemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        ])

        let data = try await perform(request)
        let decoded: IssueResponse = try JSONDecoder().decode(IssueResponse.self, from: data)
        guard decoded.success, !decoded.key.isEmpty else {
            throw FreeAIKeyError.invalidResponse
        }
        memoryApiKey = decoded.key
        try? KeychainStore.set(decoded.key, for: apiKeyKey)
        let status = Status(key: decoded.key, model: decoded.model, quota: decoded.quota)
        cached = status
        return status
    }

    /// 查询额度状态（不消耗额度）。
    func refreshQuota() async throws -> Quota {
        let status = try await currentStatus(allowIssue: false)
        let url = baseURL.appendingPathComponent("api/ai/keys/status")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(status.key, forHTTPHeaderField: "x-api-key")
        request.timeoutInterval = 20
        let data = try await perform(request)
        let decoded: StatusResponse = try JSONDecoder().decode(StatusResponse.self, from: data)
        guard decoded.success else { throw FreeAIKeyError.invalidResponse }
        cached = Status(key: status.key, model: decoded.model, quota: decoded.quota)
        return decoded.quota
    }

    /// Key 被平台吊销或额度耗尽时清除本地缓存，下次调用重新申领。
    func invalidate() {
        cached = nil
        memoryApiKey = nil
        KeychainStore.remove(apiKeyKey)
    }

    // MARK: - HTTP

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FreeAIKeyError.invalidResponse
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw FreeAIKeyError.unauthorized
        }
        if http.statusCode == 429 {
            let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            throw FreeAIKeyError.rateLimited(retryAfter: retryAfter)
        }
        guard (200...299).contains(http.statusCode) else {
            let payload = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let detail = payload?.error ?? "HTTP \(http.statusCode)"
            throw FreeAIKeyError.platformUnavailable(detail)
        }
        return data
    }
}
