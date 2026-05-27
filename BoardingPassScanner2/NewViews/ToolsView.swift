//
//  ToolsView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 27/05/2026.
//

import SwiftUI

struct ToolsView: View {
    @Environment(BoardingPassMapper.self) private var mapper

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
                    Label("Airlines (\(mapper.airlines.count))", systemImage: "airplane")
                }

                NavigationLink {
                    AirportsDatabaseView()
                } label: {
                    Label("Airports (\(mapper.airports.count))", systemImage: "airplane.departure")
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
