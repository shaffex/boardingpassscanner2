//
//  ToolsView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 27/05/2026.
//

import SwiftUI
import StoreKit
import SafariServices

private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct ToolsView: View {
    @Environment(BoardingPassMapper.self) private var mapper
    @ObservedObject private var store = StoreManager.shared

    @AppStorage("jsonVersion") private var dataVersion = 0
    @State private var isCheckingForUpdate = false
    @State private var lastUpdateResult: String?
    @State private var isRestoring = false
    @State private var showProUpgrade = false


    private var isProOwned: Bool {
        store.purchasedProductIDs.contains(StoreManager.productID_UnlockPro)
    }

    private var gold: Color { Color(red: 1.0, green: 0.80, blue: 0.22) }

    var body: some View {
        ZStack {
            List {
                Section("Version") {
                    // Status card row
                    Button {
                        guard !isProOwned else { return }
                        Haptics.tap()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showProUpgrade = true
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(isProOwned ? gold.opacity(0.18) : Color(.tertiarySystemFill))
                                    .frame(width: 44, height: 44)
                                Image(systemName: isProOwned ? "crown.fill" : "crown")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(isProOwned ? gold : .secondary)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(isProOwned ? "Pro — Unlocked" : "Free Version")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(isProOwned ? "All features active. Thank you!" : "Tap to upgrade to Pro version")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if isProOwned {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(gold)
                                    .font(.title3)
                            } else {
                                Text("UPGRADE")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundStyle(gold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(gold.opacity(0.14), in: Capsule())
                                    .overlay(Capsule().stroke(gold.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.tap()
                        isRestoring = true
                        Task {
                            await store.restorePurchases(showAlert: true)
                            await MainActor.run { isRestoring = false }
                        }
                    } label: {
                        HStack {
                            Text("Restore Purchases")
                            if isRestoring {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRestoring)
                }

                Section("Data Library") {
                    HStack {
                        Text("Data Library Version")
                        Spacer()
                        Text(dataVersion > 0 ? "\(dataVersion)" : "—")
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        AirlinesDatabaseView()
                    } label: {
                        Label("Airlines (\(mapper.airlines.count))", systemImage: "airplane")
                    }

                    NavigationLink {
                        AirportsDatabaseView()
                    } label: {
                        Label("Airports (\(mapper.airports.count))", systemImage: "airplane.departure")
                    }

                    Button {
                        Haptics.tap()
                        checkForUpdate()
                    } label: {
                        HStack {
                            Text("Check for data update")
                            if isCheckingForUpdate {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isCheckingForUpdate)

                    if let lastUpdateResult {
                        Text(lastUpdateResult)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Report an Issue") {
                    NavigationLink {
                        SafariView(url: URL(string: "https://shaffex.com/api/boardingpass2/Links/contactUs.php")!)
                            .ignoresSafeArea()
                            .navigationTitle("Report Data Issue")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Report data issue")
                            Text("Found incorrect airline or airport data? Let us know.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "TEXT_TOOLS"))

            // Pro upgrade overlay
            if showProUpgrade {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showProUpgrade = false
                        }
                    }

                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    showProUpgrade = false
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.secondary, Color(.systemFill))
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .padding([.top, .trailing], 16)
                        }
                        ScrollView {
                            ProUpgradeCard()
                                .padding(.horizontal, 16)
                                .padding(.bottom, 40)
                        }
                    }
                    .background(Color(.systemBackground), in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: -8)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showProUpgrade)
        .onChange(of: isProOwned) { _, owned in
            if owned {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    showProUpgrade = false
                }
            }
        }
    }

    private func checkForUpdate() {
        isCheckingForUpdate = true
        lastUpdateResult = nil
        Task {
            do {
                let updated = try await DataUpdater().checkForDataUpdate()
                await MainActor.run {
                    lastUpdateResult = updated ? "Data updated." : "Already up to date."
                    isCheckingForUpdate = false
                }
            } catch {
                await MainActor.run {
                    lastUpdateResult = "Update failed: \(error.localizedDescription)"
                    isCheckingForUpdate = false
                }
            }
        }
    }
}

struct AirlinesDatabaseView: View {
    @Environment(BoardingPassMapper.self) private var mapper
    @State private var query = ""

    private var filteredAirlines: [BoardingPassMapper.Airline] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return mapper.airlines }
        return mapper.airlines.filter {
            $0.name.lowercased().hasPrefix(needle) || $0.code.lowercased().hasPrefix(needle)
        }
    }

    var body: some View {
        List(filteredAirlines, id: \.code) { airline in
            HStack {
                Text(airline.name)
                Spacer()
                Text(airline.code)
                    .foregroundStyle(.secondary)
                    .font(.system(.subheadline, design: .monospaced))
            }
        }
        .searchable(text: $query)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .navigationTitle("Airlines (\(mapper.airlines.count))")
        .overlay {
            if mapper.airlines.isEmpty {
                ContentUnavailableView(
                    "No Airlines",
                    systemImage: "airplane.circle",
                    description: Text("Use \"Check for data update\" to download the database.")
                )
            }
        }
    }
}

struct AirportsDatabaseView: View {
    @Environment(BoardingPassMapper.self) private var mapper
    @State private var query = ""

    private var filteredAirports: [BoardingPassMapper.Airport] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return mapper.airports }
        return mapper.airports.filter {
            $0.name.lowercased().hasPrefix(needle) || $0.code.lowercased().hasPrefix(needle)
        }
    }

    var body: some View {
        List(filteredAirports, id: \.code) { airport in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(airport.name)
                        .font(.body)
                    Spacer()
                    Text(airport.code)
                        .foregroundStyle(.secondary)
                        .font(.system(.subheadline, design: .monospaced))
                }
                if !airport.city.isEmpty || !airport.country.isEmpty {
                    Text([airport.city, airport.country].filter { !$0.isEmpty }.joined(separator: ", "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $query)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .navigationTitle("Airports (\(mapper.airports.count))")
        .overlay {
            if mapper.airports.isEmpty {
                ContentUnavailableView(
                    "No Airports",
                    systemImage: "airplane.departure",
                    description: Text("Use \"Check for data update\" to download the database.")
                )
            }
        }
    }
}

struct ToolsPluginView: View {
    var body: some View {
        ToolsView()
    }
}
