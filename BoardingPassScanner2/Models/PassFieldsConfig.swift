//
//  PassFieldsConfig.swift
//  BoardingPassScanner2
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// Apple Wallet boarding-pass zone capacities (per Apple's PassKit docs).
enum PassZoneCapacity {
    static let header = 1
    static let primary = 2
    static let secondary = 4
    static let auxiliary = 4
}

// A value source for a single field on the wallet pass.
enum PassFieldAttribute: String, CaseIterable, Codable, Identifiable {
    case none
    case passengerName
    case passengerSurname
    case passengerGivenName
    case flightCode
    case flightNumber
    case airlineName
    case fromAirport
    case fromAirportCity
    case fromAirportName
    case toAirport
    case toAirportCity
    case toAirportName
    case flightDate
    case departureTime
    case seatNumber
    case compartmentCode
    case pnr
    case sequenceNumber
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "— (empty)"
        case .passengerName: return "Passenger name"
        case .passengerSurname: return "Passenger surname"
        case .passengerGivenName: return "Passenger given name"
        case .flightCode: return "Flight code"
        case .flightNumber: return "Flight number"
        case .airlineName: return "Airline name"
        case .fromAirport: return "From (code)"
        case .fromAirportCity: return "From (city)"
        case .fromAirportName: return "From (name)"
        case .toAirport: return "To (code)"
        case .toAirportCity: return "To (city)"
        case .toAirportName: return "To (name)"
        case .flightDate: return "Date"
        case .departureTime: return "Departure time"
        case .seatNumber: return "Seat"
        case .compartmentCode: return "Class"
        case .pnr: return "PNR"
        case .sequenceNumber: return "Sequence no."
        case .custom: return "Custom text"
        }
    }

    var defaultLabel: String {
        switch self {
        case .none, .custom: return ""
        case .passengerName, .passengerSurname, .passengerGivenName: return "PASSENGER"
        case .flightCode, .flightNumber: return "FLIGHT"
        case .airlineName: return "AIRLINE"
        case .fromAirport, .fromAirportCity, .fromAirportName: return "FROM"
        case .toAirport, .toAirportCity, .toAirportName: return "TO"
        case .flightDate: return "DATE"
        case .departureTime: return "DEPART"
        case .seatNumber: return "SEAT"
        case .compartmentCode: return "CLASS"
        case .pnr: return "PNR"
        case .sequenceNumber: return "SEQ"
        }
    }
}

struct PassFieldEntry: Codable, Identifiable, Hashable, Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .passFieldEntry)
    }

    var id = UUID()
    var attribute: PassFieldAttribute
    var label: String
    var customValue: String
    var isVisible: Bool

    init(
        attribute: PassFieldAttribute,
        label: String? = nil,
        customValue: String = "",
        isVisible: Bool = true
    ) {
        self.attribute = attribute
        self.label = label ?? attribute.defaultLabel
        self.customValue = customValue
        self.isVisible = isVisible
    }

    static let empty = PassFieldEntry(attribute: .none, isVisible: false)
}

struct PassFieldsConfig: Codable, Hashable {
    var logoText: String = ""
    var headerFields: [PassFieldEntry]
    var primaryFields: [PassFieldEntry]
    var secondaryFields: [PassFieldEntry]
    var auxiliaryFields: [PassFieldEntry]
    var backFields: [PassFieldEntry]

    static let `default` = PassFieldsConfig(
        headerFields: [
            PassFieldEntry(attribute: .flightCode, label: "FLIGHT")
        ],
        primaryFields: [
            PassFieldEntry(attribute: .fromAirport, label: "FROM"),
            PassFieldEntry(attribute: .toAirport, label: "TO")
        ],
        secondaryFields: [
            PassFieldEntry(attribute: .passengerName, label: "PASSENGER"),
            PassFieldEntry(attribute: .seatNumber, label: "SEAT"),
            PassFieldEntry.empty,
            PassFieldEntry.empty
        ],
        auxiliaryFields: [
            PassFieldEntry(attribute: .flightDate, label: "DATE"),
            PassFieldEntry(attribute: .departureTime, label: "DEPART"),
            PassFieldEntry(attribute: .sequenceNumber, label: "SEQ"),
            PassFieldEntry.empty
        ],
        backFields: [
            PassFieldEntry(attribute: .pnr, label: "Booking reference"),
            PassFieldEntry(attribute: .airlineName, label: "Airline")
        ]
    )

    // Build a flat dictionary describing the configured fields, ready to be
    // JSON-encoded and sent to the wallet endpoint. Only visible fields are
    // included; values are resolved against the supplied record.
    func resolved(for record: BoardingPassRecord, departureTimeOverride: Date? = nil) -> [String: Any] {
        var dict: [String: Any] = [
            "headerFields": uniqueKeyed(headerFields.compactMap { $0.serialised(for: record, departureTimeOverride: departureTimeOverride) }),
            "primaryFields": uniqueKeyed(primaryFields.compactMap { $0.serialised(for: record, departureTimeOverride: departureTimeOverride) }),
            "secondaryFields": uniqueKeyed(secondaryFields.compactMap { $0.serialised(for: record, departureTimeOverride: departureTimeOverride) }),
            "auxiliaryFields": uniqueKeyed(auxiliaryFields.compactMap { $0.serialised(for: record, departureTimeOverride: departureTimeOverride) }),
            "backFields": uniqueKeyed(backFields.compactMap { $0.serialised(for: record, departureTimeOverride: departureTimeOverride) })
        ]
        if !logoText.isEmpty { dict["logoText"] = logoText }
        return dict
    }

    private func uniqueKeyed(_ fields: [[String: String]]) -> [[String: String]] {
        var counts: [String: Int] = [:]
        for f in fields { if let k = f["key"] { counts[k, default: 0] += 1 } }
        var seen: [String: Int] = [:]
        return fields.map { f in
            guard let key = f["key"], counts[key]! > 1 else { return f }
            let idx = seen[key, default: 0]
            seen[key] = idx + 1
            var updated = f
            updated["key"] = "\(key)_\(idx)"
            return updated
        }
    }

    func jsonString(for record: BoardingPassRecord, departureTimeOverride: Date? = nil) -> String {
        let data = try? JSONSerialization.data(withJSONObject: resolved(for: record, departureTimeOverride: departureTimeOverride))
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
}

private extension PassFieldEntry {
    func serialised(for record: BoardingPassRecord, departureTimeOverride: Date? = nil) -> [String: String]? {
        guard isVisible, attribute != .none else { return nil }
        let value = resolvedValue(for: record, departureTimeOverride: departureTimeOverride)
        guard !value.isEmpty else { return nil }
        return [
            "key": attribute.rawValue,
            "label": label,
            "value": value
        ]
    }

    func resolvedValue(for record: BoardingPassRecord, departureTimeOverride: Date? = nil) -> String {
        switch attribute {
        case .none: return ""
        case .custom: return customValue
        case .passengerName: return record.name
        case .passengerSurname: return record.passengerSurname
        case .passengerGivenName: return record.passengerGivenName
        case .flightCode: return [record.operatingCarrier, record.flightNumber].filter { !$0.isEmpty }.joined(separator: " ")
        case .flightNumber: return [record.operatingCarrier, record.flightNumber].filter { !$0.isEmpty }.joined(separator: " ")
        case .airlineName: return record.airlineName
        case .fromAirport: return record.fromAirport
        case .fromAirportCity: return record.fromAirportCity
        case .fromAirportName: return record.fromAirportName
        case .toAirport: return record.toAirport
        case .toAirportCity: return record.toAirportCity
        case .toAirportName: return record.toAirportName
        case .flightDate: return record.flightDate.formatted(.dateTime.day().month(.abbreviated))
        case .departureTime:
            let date = departureTimeOverride ?? record.flightDate
            return date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        case .seatNumber: return record.seatNumber.replacingOccurrences(of: "^0+(?=\\d)", with: "", options: .regularExpression)
        case .compartmentCode: return record.compartmentCode
        case .pnr: return record.pnr
        case .sequenceNumber: return record.checkInSequenceNumber
        }
    }
}

extension UTType {
    static let passFieldEntry = UTType(exportedAs: "com.shaffex.boardingpassscanner2.field-entry")
}
