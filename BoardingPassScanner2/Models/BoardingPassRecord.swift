//
//  BoardingPassRecord.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import Foundation
import SwiftData

@Model
final class BoardingPassRecord {
    var text: String = ""
    var type: String = ""
    var flightDateYear: Int = 0

    init(
        text: String,
        type: String,
        flightDateYear: Int = 0
    ) {
        self.text = text
        self.type = type
        self.flightDateYear = flightDateYear
    }
}

extension BoardingPassRecord {
    var boardingPass: BoardingPass? {
        BoardingPassParseCache.shared.boardingPass(for: text, flightDateYear: resolvedFlightDateYear)
    }

    var decodedLegs: [BoardingPass.Leg] {
        boardingPass?.legs ?? []
    }

    var name: String {
        boardingPass?.passengerName.displayName ?? "Unknown passenger"
    }

    var formatCode: String {
        boardingPass?.formatCode ?? ""
    }

    var numberOfLegs: Int {
        boardingPass?.numberOfLegs ?? 0
    }

    var passengerSurname: String {
        boardingPass?.passengerName.surname ?? ""
    }

    var passengerGivenName: String {
        boardingPass?.passengerName.givenName ?? ""
    }

    var electronicTicketIndicator: String {
        boardingPass?.electronicTicketIndicator ?? ""
    }

    var pnr: String {
        boardingPass?.operatingCarrierPNR ?? ""
    }

    var fromAirport: String {
        boardingPass?.fromAirport ?? ""
    }

    var fromAirportName: String {
        BoardingPassMapper.airport(for: fromAirport)?.name ?? fromAirport
    }

    var fromAirportCity: String {
        BoardingPassMapper.airport(for: fromAirport)?.city ?? ""
    }

    var fromAirportCountry: String {
        BoardingPassMapper.airport(for: fromAirport)?.country ?? ""
    }

    var toAirport: String {
        boardingPass?.toAirport ?? ""
    }

    var toAirportName: String {
        BoardingPassMapper.airport(for: toAirport)?.name ?? toAirport
    }

    var toAirportCity: String {
        BoardingPassMapper.airport(for: toAirport)?.city ?? ""
    }

    var toAirportCountry: String {
        BoardingPassMapper.airport(for: toAirport)?.country ?? ""
    }

    var operatingCarrier: String {
        boardingPass?.operatingCarrierDesignator ?? ""
    }

    var airlineName: String {
        BoardingPassMapper.airline(for: operatingCarrier)?.name ?? operatingCarrier
    }

    var airlineCountry: String {
        BoardingPassMapper.airline(for: operatingCarrier)?.country ?? ""
    }

    var flightNumber: String {
        boardingPass?.flightNumber ?? ""
    }

    var flightDateJulian: Int {
        boardingPass?.flightDateJulian ?? 0
    }

    var flightDate: Date {
        guard let flightDate = boardingPass?.flightDate else {
            return .distantPast
        }
        return Self.iso8601Formatter.date(from: flightDate) ?? .distantPast
    }

    private static let iso8601Formatter = ISO8601DateFormatter()

    var compartmentCode: String {
        boardingPass?.compartmentCode ?? ""
    }

    var seatNumber: String {
        boardingPass?.seatNumber ?? ""
    }

    var checkInSequenceNumber: String {
        boardingPass?.checkInSequenceNumber ?? ""
    }

    var passengerStatus: String {
        boardingPass?.passengerStatus ?? ""
    }

    private var resolvedFlightDateYear: Int? {
        flightDateYear > 0 ? flightDateYear : nil
    }

    static func from(
        barcodeText: String,
        barcodeType: String,
        flightDateYear: Int? = nil
    ) -> BoardingPassRecord? {
        guard let boardingPass = try? BoardingPass(parsing: barcodeText, flightDateYear: flightDateYear) else {
            return BoardingPassRecord(
                text: barcodeText,
                type: barcodeType.isEmpty ? "Boarding pass" : barcodeType
            )
        }

        let resolvedYear = flightDateYear
            ?? ISO8601DateFormatter()
                .date(from: boardingPass.flightDate)
                .map { Calendar.current.component(.year, from: $0) }
            ?? 0

        return BoardingPassRecord(
            text: barcodeText,
            type: barcodeType.isEmpty ? "Boarding pass" : barcodeType,
            flightDateYear: resolvedYear
        )
    }

    func applyMapperRefresh() {
        // Mapping fields are derived at display time, so refreshed airline/airport data is visible immediately.
    }
}

final class BoardingPassParseCache {
    static let shared = BoardingPassParseCache()

    private struct Key: Hashable {
        let text: String
        let flightDateYear: Int
    }

    private var cache: [Key: BoardingPass] = [:]

    func boardingPass(for text: String, flightDateYear: Int?) -> BoardingPass? {
        let key = Key(text: text, flightDateYear: flightDateYear ?? 0)
        if let cached = cache[key] {
            return cached
        }
        guard let parsed = try? BoardingPass(parsing: text, flightDateYear: flightDateYear) else {
            return nil
        }
        cache[key] = parsed
        return parsed
    }

    func warm(text: String, flightDateYear: Int?) {
        _ = boardingPass(for: text, flightDateYear: flightDateYear)
    }

    func invalidate(text: String) {
        cache = cache.filter { $0.key.text != text }
    }
}
