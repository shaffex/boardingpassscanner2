//
//  MyBoardingPassesView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import SwiftUI
import SwiftData
import MagicUiFramework

struct MyBoardingPassesView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BoardingPassRecord.scannedDate, order: .reverse)
    private var records: [BoardingPassRecord]

    @AppStorage("isReversed") private var isReversed: Bool = false
    @AppStorage("DEBUG_MODE") private var debugMode: Bool = false

    @State private var searchText = ""
    @State private var showDeleteAllAlert = false

    private var orderedRecords: [BoardingPassRecord] {
        isReversed ? records.reversed() : records
    }

    private var filteredRecords: [BoardingPassRecord] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return orderedRecords }

        let needle = trimmed.lowercased()
        return orderedRecords.filter { record in
            record.name.lowercased().contains(needle) || record.type.lowercased().contains(needle)
        }
    }

    private var navigationTitle: String {
        records.isEmpty
            ? String(localized: "TEXT_MY_BOARDING_PASSES")
            : String(localized: "TEXT_MY_BOARDING_PASSES (\(records.count))")
    }

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    "No Boarding Passes",
                    systemImage: "qrcode",
                    description: Text("Your saved boarding passes will appear here.")
                )
            } else {
                List {
                    ForEach(filteredRecords, id: \.persistentModelID) { record in
                        NavigationLink {
                            BoardingPassDetailView(record: record)
                        } label: {
                            BoardingPassRow(record: record)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                BoardingPassStore.shared.delete(record)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .searchable(text: $searchText)
            }
        }
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                optionsMenu
            }
            ToolbarItem(placement: .topBarTrailing) {
                addMenu
            }
        }
        .alert("Warning", isPresented: $showDeleteAllAlert) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) {
                BoardingPassStore.shared.deleteAll()
            }
        } message: {
            Text("Are you sure you want to delete all saved boarding passes?\n\nPlease note, this action is irreversible.")
        }
        .onAppear {
            Task {
                try? await DataUpdater().checkForDataUpdate()
            }
        }
    }

    private var optionsMenu: some View {
        Menu {
            if debugMode {
                Button("DEBUG: ScanSimulator") {
                    PluginActions.shared.runAction("presentSheet:item:sheetItem;id:sheetScanSimulatorView")
                }
            }
            Button {
                PluginActions.shared.runAction("importCodes")
            } label: {
                Label("Import codes", systemImage: "tray.and.arrow.down")
            }
            Button {
                PluginActions.shared.runAction("exportCodes")
            } label: {
                Label("Export codes", systemImage: "tray.and.arrow.up")
            }
            .disabled(records.isEmpty)
            Button(role: .destructive) {
                showDeleteAllAlert = true
            } label: {
                Label("Delete all boarding passes", systemImage: "trash")
            }
            .disabled(records.isEmpty)

            Divider()

            Toggle(isOn: $isReversed) { Text("Reverse Order") }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private var addMenu: some View {
        Menu {
            Button {
                PluginActions.shared.runAction("presentSheet:item:sheetItem;id:barcodeScannerView")
            } label: {
                Label("Scan New Barcode", systemImage: "qrcode.viewfinder")
            }
            Button {
                PluginActions.shared.runAction("setBool:isShowingImagePicker=true")
            } label: {
                Label("Import From Photo", systemImage: "photo.on.rectangle")
            }
        } label: {
            Image(systemName: "plus")
        }
    }
}

private struct BoardingPassRow: View {
    let record: BoardingPassRecord

    var body: some View {
        VStack(alignment: .leading) {
            Text(record.name)
                .foregroundStyle(.primary)

            HStack {
                Text(record.operatingCarrier)
                    .foregroundStyle(.blue)
                Text(record.flightNumber)
                    .foregroundStyle(.green)
                Text(record.airlineName)
                    .foregroundStyle(.red)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text(record.fromAirportCity)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(record.fromAirport)
                        .font(.largeTitle)
                        .bold()
                }

                Spacer()
                Image(systemName: "airplane")
                Spacer()

                VStack(alignment: .trailing) {
                    Text(record.toAirportCity)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(record.toAirport)
                        .font(.largeTitle)
                        .bold()
                }
            }

            Text(record.type)
                .foregroundStyle(.secondary)
                .font(.footnote)
            Text("flightDate: \(record.flightDate.formatted(date: .abbreviated, time: .shortened))")
                .foregroundStyle(.secondary)
                .font(.footnote)
        }
    }
}

struct MyBoardingPassesPluginView: View {
    var body: some View {
        MyBoardingPassesView()
            .modelContainer(BoardingPassStore.shared.container)
    }
}
