import SwiftUI
import WebKit

// MARK: - WKWebView Wrapper

struct LocalWebView: UIViewRepresentable {
    let url: URL?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = true
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = url else { return }
        if webView.url != url {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
}

// MARK: - Legal Document View

struct LegalDocumentView: View {
    enum Document {
        case privacyPolicy
        case termsOfService

        var fileName: String {
            switch self {
            case .privacyPolicy: return "PrivacyPolicy"
            case .termsOfService: return "TermsOfService"
            }
        }

        var title: String {
            switch self {
            case .privacyPolicy: return "Privacy Policy"
            case .termsOfService: return "Terms of Service"
            }
        }

        var systemImage: String {
            switch self {
            case .privacyPolicy: return "hand.raised.fill"
            case .termsOfService: return "doc.text.fill"
            }
        }
    }

    let document: Document
    @State private var loadError: String?

    var body: some View {
        ZStack {
            if let url = bundleURL(), loadError == nil {
                LocalWebView(url: url)
            } else {
                errorView
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bundleURL() -> URL? {
        if let url = Bundle.main.url(forResource: document.fileName, withExtension: "html") {
            return url
        }
        // Fallback: search recursively in bundle (folder reference resource)
        let bundlePath = Bundle.main.bundlePath
        let candidates = [
            "\(bundlePath)/Docs/\(document.fileName).html",
            "\(bundlePath)/\(document.fileName).html"
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Document Unavailable")
                .font(.headline)
            Text(loadError ?? "The \(document.title) file could not be loaded.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    NavigationStack {
        LegalDocumentView(document: .privacyPolicy)
    }
}
