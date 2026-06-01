import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var aiService = AIService.shared
    
    @State private var showingProviderPicker = false
    @State private var showingModelPicker = false
    @State private var showingApiKeyInput = false
    
    var body: some View {
        NavigationStack {
            List {
                // AI Service Status (read-only, no editing)
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
                } header: {
                    Text("AI Assistant")
                } footer: {
                    Text("AI service is pre-configured and ready to use")
                }
                
                // Custom AI Providers Section
                Section {
                    ForEach(AIProviderType.allCases.filter { $0 != .minimax }, id: \.self) { provider in
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
                                    Text("Tap to configure")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Custom AI Providers")
                } footer: {
                    Text("9 additional AI providers available. Select one to configure with your own API Key")
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
            .onAppear {
                // AI service is pre-configured, no user action needed
            }
        }
    }
    
    // AI service is pre-configured — no user configuration needed
    private func loadCurrentSettings() {}
    
    private func updateProvider(_ provider: AIProviderType) {}
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
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Provider")
                    Spacer()
                    Text(provider.displayName)
                        .foregroundColor(.secondary)
                }
                
                TextField("Base URL", text: $baseURL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                
                TextField("API Key", text: $apiKey)
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
                Text("Enter the base URL and API Key for \(provider.displayName)")
            }
            
            Section {
                Button {
                    testConnection()
                } label: {
                    HStack {
                        Text("Test Connection")
                        Spacer()
                        if isTesting {
                            ProgressView()
                        } else if let result = testResult {
                            Text(result)
                                .foregroundColor(result == "Success" ? .green : .red)
                        }
                    }
                }
                .disabled(baseURL.isEmpty || apiKey.isEmpty)
                
                Button("Save") {
                    AIService.shared.configureCustomProvider(
                        provider,
                        baseURL: baseURL,
                        apiKey: apiKey,
                        model: selectedModel
                    )
                    dismiss()
                }
                .disabled(baseURL.isEmpty || apiKey.isEmpty)
            }
        }
        .navigationTitle("Configure \(provider.displayName)")
        .onAppear {
            selectedModel = provider.defaultModel
        }
    }
    
    private func testConnection() {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return }
        isTesting = true
        testResult = nil
        
        Task {
            do {
                let tempURL = AIService.shared.currentProvider.baseURL
                let tempKey = AIService.shared.apiKey
                // Temporarily set custom config
                AIService.shared.configureCustomProvider(provider, baseURL: baseURL, apiKey: apiKey, model: selectedModel)
                let _ = try await AIService.shared.sendMessage("Test", history: [])
                await MainActor.run {
                    testResult = "Success"
                    isTesting = false
                }
                // Restore original config
                AIService.shared.configureCustomProvider(AIService.shared.currentProvider, baseURL: tempURL, apiKey: tempKey, model: AIService.shared.selectedModel)
            } catch {
                await MainActor.run {
                    testResult = "Failed"
                    isTesting = false
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
