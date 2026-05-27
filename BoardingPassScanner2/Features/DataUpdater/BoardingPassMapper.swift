//
//  BoardingPassMapper.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import Foundation

extension Notification.Name {
    static let boardingPassMapperDidReload = Notification.Name("BoardingPassMapperDidReload")
}

struct BoardingPassMapper {
    struct Airport {
        let code: String
        let name: String
        let city: String
        let country: String
    }

    struct Airline {
        let code: String
        let name: String
        let country: String
    }

    static func airline(for code: String) -> Airline? {
        guard !code.isEmpty else { return nil }
        loadIfNeeded()
        return airlinesIndex[code.uppercased()]
    }

    static func airport(for code: String) -> Airport? {
        guard !code.isEmpty else { return nil }
        loadIfNeeded()
        return airportsIndex[code.uppercased()]
    }

    static func airlineName(for code: String) -> String {
        airline(for: code)?.name ?? code
    }

    static func airportName(for code: String) -> String {
        airport(for: code)?.name ?? code
    }

    static func reload() {
        airlinesIndex = parseAirlines(at: airlinesFileURL)
        airportsIndex = parseAirports(at: airportsFileURL)
        didLoad = true
        NotificationCenter.default.post(name: .boardingPassMapperDidReload, object: nil)
    }

    static func allAirlines() -> [Airline] {
        loadIfNeeded()
        return airlinesIndex.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func allAirports() -> [Airport] {
        loadIfNeeded()
        return airportsIndex.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func installForTesting(airlines: [Airline], airports: [Airport]) {
        airlinesIndex = Dictionary(uniqueKeysWithValues: airlines.map { ($0.code.uppercased(), $0) })
        airportsIndex = Dictionary(uniqueKeysWithValues: airports.map { ($0.code.uppercased(), $0) })
        didLoad = true
    }

    static func resetForTesting() {
        airlinesIndex = [:]
        airportsIndex = [:]
        didLoad = false
    }

    static var airlinesFileURL: URL {
        (try? dataDirectory().appendingPathComponent("airlines.csv"))
            ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("airlines.csv")
    }

    static var airportsFileURL: URL {
        (try? dataDirectory().appendingPathComponent("airports.csv"))
            ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("airports.csv")
    }

    static func dataDirectory() throws -> URL {
        let fileManager = FileManager.default
        let supportDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = supportDirectory.appendingPathComponent("BoardingPassData", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            var excluded = URLResourceValues()
            excluded.isExcludedFromBackup = true
            var mutableDirectory = directory
            try? mutableDirectory.setResourceValues(excluded)
        }
        return directory
    }

    private static var airlinesIndex: [String: Airline] = [:]
    private static var airportsIndex: [String: Airport] = [:]
    private static var didLoad = false

    private static func loadIfNeeded() {
        guard !didLoad else { return }
        reload()
    }

    private static func parseAirlines(at url: URL) -> [String: Airline] {
        var result: [String: Airline] = [:]
        forEachCSVRow(at: url) { fields, columnIndex in
            guard let codeColumn = columnIndex["code"], codeColumn < fields.count else { return }
            let code = fields[codeColumn]
            guard !code.isEmpty else { return }
            result[code.uppercased()] = Airline(
                code: code,
                name: value(fields, columnIndex, "name"),
                country: value(fields, columnIndex, "country")
            )
        }
        return result
    }

    private static func parseAirports(at url: URL) -> [String: Airport] {
        var result: [String: Airport] = [:]
        forEachCSVRow(at: url) { fields, columnIndex in
            guard let codeColumn = columnIndex["code"], codeColumn < fields.count else { return }
            let code = fields[codeColumn]
            guard !code.isEmpty else { return }
            result[code.uppercased()] = Airport(
                code: code,
                name: value(fields, columnIndex, "name"),
                city: value(fields, columnIndex, "city"),
                country: value(fields, columnIndex, "country")
            )
        }
        return result
    }

    private static func value(_ fields: [String], _ columnIndex: [String: Int], _ key: String) -> String {
        guard let column = columnIndex[key], column < fields.count else { return "" }
        return fields[column]
    }

    private static func forEachCSVRow(
        at url: URL,
        body: ([String], [String: Int]) -> Void
    ) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }

        var headers: [String: Int]?
        for line in content.split(omittingEmptySubsequences: true, whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            let fields = parseCSVLine(String(line))
            if let columnIndex = headers {
                body(fields, columnIndex)
            } else {
                var index: [String: Int] = [:]
                for (offset, field) in fields.enumerated() {
                    index[field] = offset
                }
                headers = index
            }
        }
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()

        while let character = iterator.next() {
            if inQuotes {
                if character == "\"" {
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else if next == "," {
                            inQuotes = false
                            fields.append(current)
                            current = ""
                        } else {
                            inQuotes = false
                            current.append(next)
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(character)
                }
            } else {
                if character == "," {
                    fields.append(current)
                    current = ""
                } else if character == "\"" && current.isEmpty {
                    inQuotes = true
                } else {
                    current.append(character)
                }
            }
        }
        fields.append(current)
        return fields
    }
}
