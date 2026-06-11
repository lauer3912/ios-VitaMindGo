//
//  PaywallView.swift
//  VitaMindGo
//
//  v3.1.0 IAP/订阅付费墙. 3 卡片布局: Monthly / Yearly (推荐) / 7 天试用.
//  Apple App Store 审核要求:
//   - 明确显示价格 + 续费条款 (Guideline 3.1.2)
//   - 加 "Restore Purchases" 按钮 (Guideline 3.1.5)
//   - 不藏订阅价值, 清楚列出 Pro 解锁什么
//
//  Phase 2 of v3.1.0 IAP plan (docs/v3.1.0-IAP-Plan.md §2.3).
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscription = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProductID: String = "vitamind_pro_yearly"  // 默认勾选 Yearly
    @State private var isPurchasing: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                VitaTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        benefitsSection
                        pricingCards
                        purchaseButton
                        legalFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }

                if subscription.isPurchasing {
                    purchasingOverlay
                }
            }
            .navigationTitle("VitaMindGo Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(VitaTheme.Colors.textSecondary)
                }
            }
            .alert("Subscription Error",
                   isPresented: Binding(
                    get: { subscription.lastError != nil },
                    set: { if !$0 { /* error stays until next action */ } }
                   ),
                   presenting: subscription.lastError) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error)
            }
        }
        .task {
            // Ensure products are loaded when view appears
            if subscription.products.isEmpty {
                await subscription.loadProducts()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [VitaTheme.Colors.primary, VitaTheme.Colors.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Unlock VitaMindGo Pro")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(VitaTheme.Colors.textPrimary)

            Text("Get unlimited AI Coach, advanced insights, and exclusive card themes.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(VitaTheme.Colors.textSecondary)
                .padding(.horizontal, 12)
        }
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PaywallBenefitRow(
                icon: "infinity",
                title: "Unlimited AI Coach",
                description: "Free tier is limited to 5 chats per day. Pro is unlimited."
            )
            PaywallBenefitRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Insights",
                description: "Heart rate variability trends, habit predictions, and more."
            )
            PaywallBenefitRow(
                icon: "applewatch",
                title: "Watch Power-User",
                description: "Smart Stack widgets and live complications."
            )
            PaywallBenefitRow(
                icon: "sparkles",
                title: "Exclusive Card Themes",
                description: "Unlock Legendary cards and limited-edition themes."
            )
        }
        .padding(20)
        .background(VitaTheme.Colors.surface)
        .cornerRadius(16)
    }

    // MARK: - Pricing Cards

    private var pricingCards: some View {
        VStack(spacing: 12) {
            ForEach(subscription.products, id: \.id) { product in
                PricingCard(
                    product: product,
                    isSelected: selectedProductID == product.id,
                    savings: savingsText(for: product)
                ) {
                    selectedProductID = product.id
                }
            }

            if subscription.products.isEmpty {
                loadingPlaceholder
            }
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Loading subscription options…")
                .font(.caption)
                .foregroundColor(VitaTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(VitaTheme.Colors.surface)
        .cornerRadius(16)
    }

    private func savingsText(for product: Product) -> String? {
        guard product.id == "vitamind_pro_yearly" else { return nil }
        // Yearly is 39.99, Monthly is 4.99. Per-month cost: 3.33. Save ~33%.
        return "Save 33% vs monthly"
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        VStack(spacing: 8) {
            Button {
                Task { await purchase() }
            } label: {
                HStack {
                    if subscription.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(purchaseButtonTitle)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [VitaTheme.Colors.primary, VitaTheme.Colors.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .disabled(subscription.products.isEmpty || subscription.isPurchasing)

            Button {
                Task { await subscription.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(VitaTheme.Colors.textSecondary)
            }
            .disabled(subscription.isPurchasing)
        }
    }

    private var purchaseButtonTitle: String {
        guard let selected = subscription.products.first(where: { $0.id == selectedProductID }) else {
            return "Start Free Trial"
        }
        if selected.id == "vitamind_pro_yearly" {
            return "Start 7-Day Free Trial"
        } else {
            return "Subscribe \(selected.displayPrice)/mo"
        }
    }

    private func purchase() async {
        guard let selected = subscription.products.first(where: { $0.id == selectedProductID }) else {
            return
        }
        let success = await subscription.purchase(selected)
        if success {
            dismiss()
        }
    }

    // MARK: - Legal Footer

    private var legalFooter: some View {
        VStack(spacing: 6) {
            Text("Auto-renews until cancelled. Cancel anytime in Settings → Apple ID → Subscriptions.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(VitaTheme.Colors.textSecondary)

            HStack(spacing: 16) {
                Link("Privacy Policy",
                     destination: URL(string: "https://lauer3912.github.io/ios-VitaMindGo/PrivacyPolicy.html")!)
                Link("Terms of Service",
                     destination: URL(string: "https://lauer3912.github.io/ios-VitaMindGo/TermsOfService.html")!)
            }
            .font(.caption2)
            .foregroundColor(VitaTheme.Colors.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Purchasing Overlay

    private var purchasingOverlay: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                    Text("Processing purchase…")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            )
    }
}

// MARK: - Benefit Row

private struct PaywallBenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(VitaTheme.Colors.primary)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(VitaTheme.Colors.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(VitaTheme.Colors.textSecondary)
            }
            Spacer()
        }
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let savings: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? VitaTheme.Colors.primary : VitaTheme.Colors.textSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.headline)
                            .foregroundColor(VitaTheme.Colors.textPrimary)
                        if let savings {
                            Text(savings)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(VitaTheme.Colors.accent.opacity(0.2))
                                .foregroundColor(VitaTheme.Colors.accent)
                                .cornerRadius(4)
                        }
                    }
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(VitaTheme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                        .foregroundColor(VitaTheme.Colors.textPrimary)
                    Text(periodSuffix)
                        .font(.caption)
                        .foregroundColor(VitaTheme.Colors.textSecondary)
                }
            }
            .padding(16)
            .background(
                isSelected
                ? VitaTheme.Colors.primary.opacity(0.1)
                : VitaTheme.Colors.surface
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? VitaTheme.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private var displayName: String {
        if product.id.contains("yearly") { return "Yearly" }
        if product.id.contains("monthly") { return "Monthly" }
        return product.displayName
    }

    private var periodSuffix: String {
        if product.id.contains("yearly") { return "per year" }
        if product.id.contains("monthly") { return "per month" }
        return ""
    }
}

// MARK: - Preview

#Preview("Paywall") {
    PaywallView()
        .environmentObject(GameState())
}
