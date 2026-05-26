//
//  MyBoardingPassesView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import MagicUiFramework

struct MyBoardingPassesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \BoardingPassRecord.scannedDate, order: .reverse)
    private var records: [BoardingPassRecord]

    @AppStorage("isReversed") private var isReversed: Bool = false
    @AppStorage("DEBUG_MODE") private var debugMode: Bool = false

    @State private var searchText = ""
    @State private var showDeleteAllAlert = false
    @State private var isShowingExporter = false
    @State private var exportDocument = BoardingPassCSVDocument(records: [])
    @State private var selectedSegment: PassSegment = .upcoming

    private var orderedRecords: [BoardingPassRecord] {
        isReversed ? records.reversed() : records
    }

    private var upcomingRecords: [BoardingPassRecord] {
        orderedRecords.filter { Calendar.current.startOfDay(for: $0.flightDate) >= Calendar.current.startOfDay(for: .now) }
    }

    private var pastRecords: [BoardingPassRecord] {
        orderedRecords.filter { Calendar.current.startOfDay(for: $0.flightDate) < Calendar.current.startOfDay(for: .now) }
    }

    private var visibleRecords: [BoardingPassRecord] {
        let segmentRecords = selectedSegment == .upcoming ? upcomingRecords : pastRecords
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return segmentRecords }

        let needle = trimmed.lowercased()
        return segmentRecords.filter { record in
            [
                record.name,
                record.type,
                record.operatingCarrier,
                record.flightNumber,
                record.airlineName,
                record.fromAirport,
                record.fromAirportCity,
                record.toAirport,
                record.toAirportCity
            ]
            .contains { $0.lowercased().contains(needle) }
        }
    }

    var body: some View {
        ZStack {
            screenBackground.ignoresSafeArea()

            if records.isEmpty {
                ContentUnavailableView(
                    "No Boarding Passes",
                    systemImage: "qrcode",
                    description: Text("Your saved boarding passes will appear here.")
                )
                .foregroundStyle(primaryText)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("My Passes")
                            .font(.system(size: 48, weight: .semibold, design: .default))
                            .foregroundStyle(primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        searchField

                        segmentControl

                        LazyVStack(spacing: 16) {
                            ForEach(visibleRecords, id: \.persistentModelID) { record in
                                NavigationLink {
                                    BoardingPassDetailView(record: record)
                                } label: {
                                    BoardingPassCard(record: record)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        BoardingPassStore.shared.delete(record)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                optionsMenu
            }
            ToolbarItem(placement: .topBarTrailing) {
                addMenu
            }
        }
        .fileExporter(
            isPresented: $isShowingExporter,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "BoardingPasses.csv"
        ) { result in
            if case .failure(let error) = result {
                print("[MyBoardingPassesView] CSV export failed: \(error)")
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
            if upcomingRecords.isEmpty, !pastRecords.isEmpty {
                selectedSegment = .past
            }

            Task {
                try? await DataUpdater().checkForDataUpdate()
            }
        }
    }

    private var screenBackground: Color {
        colorScheme == .dark ? .black : Color(uiColor: .systemGroupedBackground)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var controlBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white
    }

    private var selectedSegmentBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.13) : Color(uiColor: .secondarySystemGroupedBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    private var selectedBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.12)
    }


    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Search name, route, flight...", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(.title3)
                .foregroundStyle(primaryText)
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(controlBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        }
    }

    private var segmentControl: some View {
        HStack(spacing: 18) {
            segmentButton(.upcoming, count: upcomingRecords.count)
            segmentButton(.past, count: pastRecords.count)
            Spacer(minLength: 0)
        }
    }

    private func segmentButton(_ segment: PassSegment, count: Int) -> some View {
        Button {
            selectedSegment = segment
        } label: {
            HStack(spacing: 10) {
                Text(segment.title)
                    .font(.headline)
                Text(count.formatted())
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(selectedSegment == segment ? primaryText.opacity(0.7) : .secondary)
            }
            .foregroundStyle(selectedSegment == segment ? primaryText : .secondary)
            .padding(.horizontal, 22)
            .frame(height: 48)
            .background {
                if selectedSegment == segment {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selectedSegmentBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selectedBorderColor, lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(.plain)
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
                exportDocument = BoardingPassCSVDocument(records: Array(records))
                isShowingExporter = true
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
                .foregroundStyle(primaryText)
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
                .foregroundStyle(primaryText)
        }
    }
}

private enum PassSegment {
    case upcoming
    case past

    var title: String {
        switch self {
        case .upcoming:
            "Upcoming"
        case .past:
            "Past"
        }
    }
}

struct MyBoardingPassesPluginView: View {
    var body: some View {
        MyBoardingPassesView()
            .modelContainer(BoardingPassStore.shared.container)
    }
}

struct BoardingPassCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    private let csvText: String

    init(records: [BoardingPassRecord]) {
        csvText = Self.makeCSV(records: records)
    }

    init(configuration: ReadConfiguration) throws {
        csvText = ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(csvText.utf8))
    }

    private static func makeCSV(records: [BoardingPassRecord]) -> String {
        let headers = [
            "type",
            "scannedDate",
            "passengerName",
            "passengerSurname",
            "passengerGivenName",
            "pnr",
            "fromAirport",
            "fromAirportName",
            "fromAirportCity",
            "fromAirportCountry",
            "toAirport",
            "toAirportName",
            "toAirportCity",
            "toAirportCountry",
            "operatingCarrier",
            "airlineName",
            "airlineCountry",
            "flightNumber",
            "flightDateJulian",
            "flightDate",
            "compartmentCode",
            "seatNumber",
            "checkInSequenceNumber",
            "passengerStatus",
            "summary",
            "text"
        ]

        let rows = records.map { record in
            [
                record.type,
                isoDate(record.scannedDate),
                record.name,
                record.passengerSurname,
                record.passengerGivenName,
                record.pnr,
                record.fromAirport,
                record.fromAirportName,
                record.fromAirportCity,
                record.fromAirportCountry,
                record.toAirport,
                record.toAirportName,
                record.toAirportCity,
                record.toAirportCountry,
                record.operatingCarrier,
                record.airlineName,
                record.airlineCountry,
                record.flightNumber,
                String(record.flightDateJulian),
                isoDate(record.flightDate),
                record.compartmentCode,
                record.seatNumber,
                record.checkInSequenceNumber,
                record.passengerStatus,
                record.summary,
                record.text
            ]
        }

        return ([headers] + rows)
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n") + "\n"
    }

    private static func isoDate(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
