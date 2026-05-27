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

    @Query private var records: [BoardingPassRecord]

    @AppStorage("boardingPassSortOrder") private var sortOrderRawValue = PassSortOrder.descending.rawValue

    @State private var debugMode = false
    @State private var searchText = ""
    @State private var showDeleteAllAlert = false
    @State private var isShowingExporter = false
    @State private var isShowingImporter = false
    @State private var exportDocument = BoardingPassCSVDocument(records: [])
    @State private var importErrorMessage = ""
    @State private var isShowingImportError = false
    @State private var selectedSegment: PassSegment = .upcoming

    private var orderedDatedRecords: [(record: BoardingPassRecord, date: Date)] {
        let dated = records.map { (record: $0, date: $0.flightDate) }
        switch PassSortOrder(rawValue: sortOrderRawValue) ?? .descending {
        case .descending:
            return dated.sorted { $0.date > $1.date }
        case .ascending:
            return dated.sorted { $0.date < $1.date }
        }
    }

    private var upcomingRecords: [BoardingPassRecord] {
        let today = Calendar.current.startOfDay(for: .now)
        return orderedDatedRecords
            .filter { Calendar.current.startOfDay(for: $0.date) >= today }
            .map(\.record)
    }

    private var pastRecords: [BoardingPassRecord] {
        let today = Calendar.current.startOfDay(for: .now)
        return orderedDatedRecords
            .filter { Calendar.current.startOfDay(for: $0.date) < today }
            .map(\.record)
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
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.json, .commaSeparatedText]
        ) { result in
            importCodes(from: result)
        }
        .alert("Import failed", isPresented: $isShowingImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
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
            refreshDebugMode()

            if upcomingRecords.isEmpty, !pastRecords.isEmpty {
                selectedSegment = .past
            }

            Task {
                try? await DataUpdater().checkForDataUpdate()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            refreshDebugMode()
        }
    }

    private func refreshDebugMode() {
        debugMode = MagicUiBrisge.isDebugModeEnabled
    }

    private func importCodes(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let text = try String(contentsOf: url, encoding: .utf8)
            switch url.pathExtension.lowercased() {
            case "json":
                MigrateDataFromV1().importBarcodes(jsonString: text)
            case "csv":
                try BoardingPassCSVImporter.importCSV(text)
            default:
                throw BoardingPassCSVImportError.unsupportedFileType
            }
        } catch is CancellationError {
            return
        } catch {
            importErrorMessage = error.localizedDescription
            isShowingImportError = true
            print("[MyBoardingPassesView] Import failed: \(error)")
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
            Button {
                isShowingImporter = true
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

            Picker("Sort order", selection: $sortOrderRawValue) {
                ForEach(PassSortOrder.allCases) { order in
                    Label(order.title, systemImage: order.systemImage)
                        .tag(order.rawValue)
                }
            }
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

private enum PassSortOrder: String, CaseIterable, Identifiable {
    case descending
    case ascending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .descending:
            "Descending"
        case .ascending:
            "Ascending"
        }
    }

    var systemImage: String {
        switch self {
        case .descending:
            "arrow.down"
        case .ascending:
            "arrow.up"
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
            "text"
        ]

        let rows = records.map { record in
            [
                record.type,
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

private enum BoardingPassCSVImportError: LocalizedError {
    case unsupportedFileType
    case emptyFile
    case missingRequiredColumns

    var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            "Please choose a JSON or CSV file."
        case .emptyFile:
            "The selected CSV file is empty."
        case .missingRequiredColumns:
            "The CSV file must contain at least text and type columns."
        }
    }
}

private enum BoardingPassCSVImporter {
    @MainActor
    static func importCSV(_ csvText: String) throws {
        let rows = parse(csvText)
        guard let headers = rows.first else {
            throw BoardingPassCSVImportError.emptyFile
        }

        let normalizedHeaders = headers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let textIndex = normalizedHeaders.firstIndex(of: "text"),
              let typeIndex = normalizedHeaders.firstIndex(of: "type") else {
            throw BoardingPassCSVImportError.missingRequiredColumns
        }

        let flightDateIndex = normalizedHeaders.firstIndex(of: "flightDate")
        let store = BoardingPassStore.shared

        for row in rows.dropFirst() {
            guard textIndex < row.count, typeIndex < row.count else { continue }

            let barcodeText = row[textIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            let barcodeType = row[typeIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !barcodeText.isEmpty else { continue }

            let flightDateYear = flightDateIndex.flatMap { index -> Int? in
                guard index < row.count,
                      let date = ISO8601DateFormatter().date(from: row[index]) else {
                    return nil
                }
                return Calendar.current.component(.year, from: date)
            }

            store.insertIfMissing(
                barcodeText: barcodeText,
                barcodeType: barcodeType.isEmpty ? "Boarding pass" : barcodeType,
                flightDateYear: flightDateYear
            )
        }
    }

    private static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isInsideQuotes = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]

            if character == "\"" {
                let nextIndex = text.index(after: index)
                if isInsideQuotes, nextIndex < text.endIndex, text[nextIndex] == "\"" {
                    field.append(character)
                    index = nextIndex
                } else {
                    isInsideQuotes.toggle()
                }
            } else if character == ",", !isInsideQuotes {
                row.append(field)
                field = ""
            } else if character == "\n", !isInsideQuotes {
                row.append(field)
                appendRow(row, to: &rows)
                row = []
                field = ""
            } else if character == "\r", !isInsideQuotes {
                let nextIndex = text.index(after: index)
                if nextIndex < text.endIndex, text[nextIndex] == "\n" {
                    index = nextIndex
                }
                row.append(field)
                appendRow(row, to: &rows)
                row = []
                field = ""
            } else {
                field.append(character)
            }

            index = text.index(after: index)
        }

        row.append(field)
        appendRow(row, to: &rows)
        return rows
    }

    private static func appendRow(_ row: [String], to rows: inout [[String]]) {
        if row.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            rows.append(row)
        }
    }
}
