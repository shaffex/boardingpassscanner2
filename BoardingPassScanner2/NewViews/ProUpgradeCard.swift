//
//  ProUpgradeCard.swift
//  BoardingPassScanner2
//

import SwiftUI
import StoreKit

struct ProUpgradeCard: View {
    @ObservedObject private var store = StoreManager.shared
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var isFetchingProducts = false

    private var isOwned: Bool {
        store.purchasedProductIDs.contains(StoreManager.productID_UnlockPro)
    }

    private var proProduct: Product? {
        store.products.first { $0.id == StoreManager.productID_UnlockPro }
    }

    var body: some View {
        if !isOwned {
            card
                .task {
                    guard store.products.isEmpty else { return }
                    isFetchingProducts = true
                    await store.fetchProducts()
                    isFetchingProducts = false
                }
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 22) {
            headerSection
            featureList
            purchaseSection
        }
        .padding(22)
        .background(cardGradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .top) {
            LinearGradient(colors: [.white.opacity(0.10), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 90)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("PRO", systemImage: "crown.fill")
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .foregroundStyle(gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(gold.opacity(0.18), in: Capsule())
                    .overlay(Capsule().stroke(gold.opacity(0.35), lineWidth: 1))

                Spacer()

                Text("One-time purchase")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.50))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Unlock the full experience")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text("Everything you need for every flight.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(
                title: "No ads",
                subtitle: "Clean, distraction-free interface",
                icon: "nosign",
                state: .included
            )
            featureRow(
                title: "Customize pass fields",
                subtitle: "Reorder and rename what appears on your pass",
                icon: "list.bullet.rectangle.portrait.fill",
                state: .included
            )
            featureRow(
                title: "Customize Wallet colors",
                subtitle: "Make your boarding pass uniquely yours",
                icon: "paintpalette.fill",
                state: .included
            )
            featureRow(
                title: "Unlimited CSV export",
                subtitle: "Export all your boarding passes anytime",
                icon: "arrow.up.doc.fill",
                state: .included
            )
            featureRow(
                title: "iCloud sync",
                subtitle: "All your passes on every device",
                icon: "icloud.fill",
                state: .included
            )
            featureRow(
                title: "Priority support",
                subtitle: "Get faster help when you need it",
                icon: "bubble.left.and.bubble.right.fill",
                state: .included
            )
        }
        .padding(16)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.tap()
                if let product = proProduct {
                    guard !isPurchasing else { return }
                    isPurchasing = true
                    Task {
                        await store.purchase(product)
                        await MainActor.run { isPurchasing = false }
                    }
                } else {
                    guard !isFetchingProducts else { return }
                    isFetchingProducts = true
                    Task {
                        await store.fetchProducts()
                        await MainActor.run { isFetchingProducts = false }
                    }
                }
            } label: {
                ZStack {
                    Group {
                        if isFetchingProducts {
                            HStack(spacing: 8) {
                                ProgressView().tint(.black)
                                Text("Loading…")
                                    .font(.headline.weight(.bold))
                            }
                        } else if isPurchasing {
                            ProgressView().tint(.black)
                        } else if let product = proProduct {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .font(.subheadline.weight(.bold))
                                Text("Unlock Pro — \(product.displayPrice)")
                                    .font(.headline.weight(.bold))
                            }
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline.weight(.bold))
                                Text("Retry")
                                    .font(.headline.weight(.bold))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.black)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isPurchasing || isFetchingProducts)

            Button {
                guard !isRestoring else { return }
                Haptics.tap()
                isRestoring = true
                Task {
                    await store.restorePurchases(showAlert: true)
                    await MainActor.run { isRestoring = false }
                }
            } label: {
                HStack(spacing: 6) {
                    if isRestoring {
                        ProgressView().tint(.white.opacity(0.5)).controlSize(.small)
                    }
                    Text("Restore purchases")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.50))
                }
                .frame(height: 32)
            }
            .buttonStyle(.plain)
            .disabled(isRestoring)
        }
    }

    // MARK: - Feature Row

    private enum FeatureState { case included, soon }

    private func featureRow(
        title: String,
        subtitle: String,
        icon: String,
        state: FeatureState
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(state == .included ? gold : .white.opacity(0.30))
                .frame(width: 22, alignment: .center)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(state == .included ? 1.0 : 0.50))

                    if state == .soon {
                        Text("SOON")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(gold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(gold.opacity(0.16), in: Capsule())
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: state == .included ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 16))
                .foregroundStyle(state == .included ? Color.green : .white.opacity(0.20))
                .padding(.top, 1)
        }
    }

    // MARK: - Helpers

    private var gold: Color { Color(red: 1.0, green: 0.80, blue: 0.22) }

    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.16, blue: 0.44),
                Color(red: 0.22, green: 0.06, blue: 0.42)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
