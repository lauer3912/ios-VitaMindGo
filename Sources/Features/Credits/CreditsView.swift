//
//  CreditsView.swift
//  VitaMindGo
//
//  Credits & Daily Bonus View for VitaMind
//

import SwiftUI

struct CreditsView: View {
    @State private var balance: Int = 100
    @State private var hasClaimedToday: Bool = false
    @State private var isClaiming: Bool = false
    @State private var showingPaywall: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundColor(.yellow)
                            Text("VitaMind AI Credits")
                                .font(.headline)
                            Spacer()
                            Text("\(balance) pts")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }

                        Text("Every account starts with 100 bonus credits for instant AI wellness coaching and meal analysis.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Divider()

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Daily Bonus")
                                    .font(.subheadline.bold())
                                Text("+10 credits every morning")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                claimBonus()
                            } label: {
                                if isClaiming {
                                    ProgressView()
                                } else {
                                    Text(hasClaimedToday ? "Claimed Today" : "Claim +10")
                                        .font(.subheadline.bold())
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(hasClaimedToday || isClaiming)
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Free Tier Quota")
                } footer: {
                    Text("No payment required. Points never expire while active.")
                }

                Section("Pro Pass & Unlimited Access") {
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack {
                            Label("View VitaMindGo Pro Plans", systemImage: "crown.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("AI Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .task {
                if let bal = try? await BuyservicesClient.shared.fetchBalance() {
                    balance = bal
                }
            }
        }
    }

    private func claimBonus() {
        guard !hasClaimedToday else { return }
        isClaiming = true
        _Concurrency.Task {
            if let newBal = try? await BuyservicesClient.shared.claimDailyBonus() {
                balance += newBal
            } else {
                balance += 10
            }
            hasClaimedToday = true
            isClaiming = false
        }
    }
}
