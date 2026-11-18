import Foundation

/// Coach / health-advice model calls.
///
/// Two transports, both speaking the Anthropic Messages protocol:
///  - Personal key (debug builds with `MINIMAX_API_KEY`, or a user-entered key)
///    talks to MiniMax directly.
///  - Otherwise the call goes through the TechIDaily credits platform
///    (credits.techidaily.com), which issues a per-device free key and proxies
///    the call. The upstream vendor key never reaches the device, so the
///    platform can rotate it without shipping a new build.
///
/// The legacy `api.minimax.chat` host is gone: it is deprecated and returns
/// nothing useful for new clients.
final class MiniMaxService: ObservableObject {
    static let shared = MiniMaxService()

    @Published var isLoading = false
    @Published var lastError: String?

    struct ChatMessage: Codable {
        let role: String
        let content: String
    }

    private let personalEndpoint = "https://api.minimaxi.com/anthropic/v1/messages"
    private let modelName = "MiniMax-M3"

    // MARK: - Send message

    func sendMessage(_ text: String, history: [ChatMessage] = []) async throws -> String {
        // v3.1.0 IAP: enforce free-tier daily message limit.
        // Pro users bypass; free users blocked at 5/day with .freeMessageLimitReached.
        // Record the message BEFORE the API call so concurrent calls can't
        // both squeeze through the limit check.
        let subscription = await SubscriptionManager.shared
        let allowed = await subscription.recordFreeMessageIfAllowed()
        guard allowed else {
            throw MiniMaxError.freeMessageLimitReached
        }

        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
        }

        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }

        do {
            let personalKey = ProcessInfo.processInfo.environment["MINIMAX_API_KEY"] ?? ""
            let endpoint: String
            let apiKey: String
            if !personalKey.isEmpty {
                endpoint = personalEndpoint
                apiKey = personalKey
            } else {
                let status = try await FreeAIKeyManager.shared.currentStatus()
                endpoint = FreeAIKeyManager.messagesEndpoint()
                apiKey = status.key
            }

            var messages = history
            messages.append(ChatMessage(role: "user", content: text))

            let requestBody: [String: Any] = [
                "model": modelName,
                "messages": messages.map { ["role": $0.role, "content": $0.content] },
                "max_tokens": 500,
                "temperature": 0.7,
            ]

            guard let url = URL(string: endpoint) else {
                throw MiniMaxError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            request.timeoutInterval = 60

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw MiniMaxError.unauthorized
                }
                if httpResponse.statusCode == 429 {
                    let code = payload?["code"] as? String
                    if code == "AI_DAILY_QUOTA_EXCEEDED" || code == "AI_TOTAL_QUOTA_EXCEEDED" {
                        throw MiniMaxError.freeQuotaExhausted
                    }
                    throw MiniMaxError.rateLimited
                }
                if !(200...299).contains(httpResponse.statusCode) {
                    let errorBody = (payload?["error"] as? String)
                        ?? String(data: data, encoding: .utf8)
                        ?? "Unknown error"
                    throw MiniMaxError.serverError(statusCode: httpResponse.statusCode, message: errorBody)
                }
                guard let content = payload?["content"] as? [[String: Any]] else {
                    throw MiniMaxError.emptyResponse
                }
                let reply = content.compactMap { $0["text"] as? String }.joined(separator: "\n")
                guard !reply.isEmpty else { throw MiniMaxError.emptyResponse }
                return reply
            }

            throw MiniMaxError.emptyResponse
        } catch let error as MiniMaxError {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw MiniMaxError.networkError(error)
        }
    }

    // Generate health advice based on user data
    func generateHealthAdvice(steps: Double, heartRate: Double, sleep: Double, water: Double) async throws -> String {
        let prompt = """
        You are VitaCoach, a friendly and knowledgeable health AI assistant. Based on the user's today's health data:
        - Steps: \(Int(steps))
        - Heart Rate: \(Int(heartRate)) BPM
        - Sleep: \(String(format: "%.1f", sleep)) hours
        - Water: \(Int(water)) glasses

        Provide 2-3 short, actionable health tips. Be encouraging and friendly. Keep it under 100 words total.
        """

        return try await sendMessage(prompt)
    }
}

enum MiniMaxError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case unauthorized
    case rateLimited
    case freeQuotaExhausted
    case serverError(statusCode: Int, message: String)
    case emptyResponse
    case networkError(Error)
    case freeMessageLimitReached  // v3.1.0 IAP: free user hit 5/day limit

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "MiniMax API key is not configured. Please set MINIMAX_API_KEY environment variable."
        case .invalidURL:
            return "Invalid API URL"
        case .unauthorized:
            return "Invalid API key or unauthorized access"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .freeQuotaExhausted:
            return "Free AI quota exhausted. Please try again later or add your own API key in Settings."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .emptyResponse:
            return "Empty response from API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .freeMessageLimitReached:
            return "You've used all 5 free AI Coach messages for today. Upgrade to Pro for unlimited access, or come back tomorrow!"
        }
    }
}
