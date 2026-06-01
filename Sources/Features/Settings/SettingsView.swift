import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var aiService = AIService.shared

    var body: some View {
        NavigationStack {
            List {
                // AI Service Status (read-only, pre-configured)
                Section {
                    HStack {
                        Label("AI Service", systemImage: "brain.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Ready")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Provider")
                        Spacer()
                        Text("MiniMax")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Model")
                        Spacer()
                        Text("MiniMax-M3")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("AI Assistant")
                } footer: {
                    Text("AI service is pre-configured and ready to use")
                }

                // Custom AI Providers Section
                Section {
                    ForEach(AIProviderType.allCases, id: \.self) { provider in
                        NavigationLink {
                            CustomProviderConfigView(provider: provider)
                        } label: {
                            HStack {
                                Image(systemName: provider.iconName)
                                    .frame(width: 30)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(provider.displayName)
                                        .foregroundColor(.primary)
                                    if provider == .minimax {
                                        Text("Pre-configured")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    } else {
                                        Text("Tap to configure")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if isProviderActive(provider) && provider != .minimax {
                                    Text("Active")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Custom AI Providers")
                } footer: {
                    Text("10 AI providers available. MiniMax is pre-configured.")
                }

                // App Info Section
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("3.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About VitaMindGo", systemImage: "info.circle")
                    }
                } header: {
                    Text("App Info")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func isProviderActive(_ provider: AIProviderType) -> Bool {
        return AIService.shared.currentProvider == provider
    }
}

// MARK: - Custom Provider Configuration

struct CustomProviderConfigView: View {
    let provider: AIProviderType
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var baseURL: String = ""
    @State private var selectedModel: String = ""
    @State private var isTesting = false
    @State private var testResult: String?
    @State private var isActive = false

    var body: some View {
        Form {
            // Provider Header
            Section {
                HStack {
                    Text("Provider")
                    Spacer()
                    Text(provider.displayName)
                        .foregroundColor(.secondary)
                }

                if provider == .minimax {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text("Pre-configured")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }

                if isActive {
                    HStack {
                        Text("Active")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            } header: {
                Text(provider == .minimax ? "MiniMax" : provider.displayName)
            }

            // Configuration (disabled for MiniMax)
            if provider != .minimax {
                Section {
                    TextField("Base URL", text: $baseURL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .textContentType(.URL)

                    SecureField("API Key", text: $apiKey)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    Picker("Model", selection: $selectedModel) {
                        ForEach(provider.supportedModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                } header: {
                    Text("Configuration")
                } footer: {
                    Text("Enter your \(provider.displayName) API credentials")
                }

                // Test Result
                if let result = testResult {
                    Section {
                        HStack {
                            Text("Result")
                            Spacer()
                            if result == "Success" {
                                Text("Connection successful")
                                    .foregroundColor(.green)
                            } else {
                                Text(result)
                                    .foregroundColor(.red)
                                    .lineLimit(2)
                            }
                        }
                    }
                }

                // Actions
                Section {
                    if isTesting {
                        HStack {
                            Text("Testing...")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Button("Test & Save") {
                            testAndSave()
                        }
                        .disabled(baseURL.isEmpty || apiKey.isEmpty)
                    }
                }
            }
        }
        .navigationTitle(provider == .minimax ? "MiniMax" : "Configure \(provider.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedModel = provider.defaultModel
            isActive = AIService.shared.currentProvider == provider
            if provider == .minimax {
                baseURL = provider.baseURL
                apiKey = AIService.shared.apiKey
            }
        }
    }

    private func testAndSave() {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return }
        isTesting = true
        testResult = nil

        Task {
            do {
                // Temporarily switch to this provider to test
                let previousProvider = AIService.shared.currentProvider
                let previousModel = AIService.shared.selectedModel
                let previousKey = AIService.shared.apiKey

                AIService.shared.configureCustomProvider(provider, baseURL: baseURL, apiKey: apiKey, model: selectedModel)
                let _ = try await AIService.shared.sendMessage("Hi", history: [])

                await MainActor.run {
                    testResult = "Success"
                    isTesting = false
                    isActive = true
                }
            } catch {
                await MainActor.run {
                    testResult = error.localizedDescription
                    isTesting = false
                    isActive = false
                }
            }
        }
    }
}

// MARK: - Provider Picker

struct ProviderPickerView: View {
    @Binding var selectedProvider: AIProviderType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(AIProviderType.allCases) { provider in
                Button {
                    selectedProvider = provider
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: provider.iconName)
                            .frame(width: 30)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(provider.displayName)
                                .foregroundColor(.primary)
                            Text("\(provider.supportedModels.count) models available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedProvider == provider {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select AI Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Model Picker

struct ModelPickerView: View {
    let selectedProvider: AIProviderType
    @Binding var selectedModel: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(selectedProvider.supportedModels, id: \.self) { model in
                Button {
                    selectedModel = model
                    AIService.shared.selectedModel = model
                    dismiss()
                } label: {
                    HStack {
                        Text(model)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedModel == model {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - API Key Input

struct ApiKeyInputView: View {
    @Binding var apiKey: String
    @Environment(\.dismiss) private var dismiss
    @State private var inputKey: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Enter API Key", text: $inputKey)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("API Key")
                } footer: {
                    Text("Your API Key will be securely stored on your device")
                }

                Section {
                    Button("Save") {
                        apiKey = inputKey
                        AIService.shared.configure(
                            provider: AIService.shared.currentProvider,
                            model: AIService.shared.selectedModel,
                            apiKey: inputKey
                        )
                        dismiss()
                    }
                    .disabled(inputKey.isEmpty)
                }
            }
            .navigationTitle("Enter API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                inputKey = apiKey
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("VitaMindGo")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Version 3.0.0")
                        .foregroundColor(.secondary)

                    Text("Your AI Health Companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }

            Section {
                Link(destination: URL(string: "https://lauer3912.github.io/ios-VitaMind/docs/PrivacyPolicy.html")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Link(destination: URL(string: "https://lauer3912.github.io/ios-VitaMind/docs/TermsOfService.html")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
            } header: {
                Text("Legal")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(GameState())
}