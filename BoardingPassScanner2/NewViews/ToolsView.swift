//
//  ToolsView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 27/05/2026.
//

import SwiftUI

struct ToolsView: View {
    @AppStorage("jsonVersion") private var dataVersion = 0
    @State private var isCheckingForUpdate = false
    @State private var lastUpdateResult: String?

    var body: some View {
        List {
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
                    Label("Airlines", systemImage: "airplane")
                }

                NavigationLink {
                    AirportsDatabaseView()
                } label: {
                    Label("Airports", systemImage: "airplane.departure")
                }

                Button {
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
        }
        .navigationTitle(String(localized: "TEXT_TOOLS"))
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
    @State private var query = ""
    @State private var airlines: [BoardingPassMapper.Airline] = BoardingPassMapper.allAirlines()

    private var filteredAirlines: [BoardingPassMapper.Airline] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return airlines }
        return airlines.filter {
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
        .navigationTitle("Airlines (\(airlines.count))")
        .overlay {
            if airlines.isEmpty {
                ContentUnavailableView(
                    "No Airlines",
                    systemImage: "airplane.circle",
                    description: Text("Use \"Check for data update\" to download the database.")
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .boardingPassMapperDidReload)) { _ in
            airlines = BoardingPassMapper.allAirlines()
        }
    }
}

struct AirportsDatabaseView: View {
    @State private var query = ""
    @State private var airports: [BoardingPassMapper.Airport] = BoardingPassMapper.allAirports()

    private var filteredAirports: [BoardingPassMapper.Airport] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return airports }
        return airports.filter {
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
        .navigationTitle("Airports (\(airports.count))")
        .overlay {
            if airports.isEmpty {
                ContentUnavailableView(
                    "No Airports",
                    systemImage: "airplane.departure",
                    description: Text("Use \"Check for data update\" to download the database.")
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .boardingPassMapperDidReload)) { _ in
            airports = BoardingPassMapper.allAirports()
        }
    }
}

struct ToolsPluginView: View {
    var body: some View {
        ToolsView()
    }
}
