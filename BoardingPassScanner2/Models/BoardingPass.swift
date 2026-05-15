//
//  BoardingPass.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 11/05/2026.
//

import Foundation

struct BoardingPass: Equatable {
    let rawValue: String
    let formatCode: String
    let numberOfLegs: Int
    let passengerName: PassengerName
    let electronicTicketIndicator: String
    let operatingCarrierPNR: String
    let fromAirport: String
    let toAirport: String
    let operatingCarrierDesignator: String
    let flightNumber: String
    let flightDateJulian: Int
    let flightDate: String
    let compartmentCode: String
    let seatNumber: String
    let checkInSequenceNumber: String
    let passengerStatus: String
}

extension BoardingPass {
    struct PassengerName: Equatable {
        let surname: String
        let givenName: String

        var displayName: String {
            [givenName, surname]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }

    enum ParseError: Error, Equatable {
        case tooShort
        case invalidFormatCode(String)
        case invalidNumberOfLegs(String)
        case invalidFlightDate(String)
    }

    init(
        parsing rawValue: String,
        flightDateYear: Int = Calendar.current.component(.year, from: Date())
    ) throws {
        let scanner = FixedWidthScanner(rawValue)

        guard scanner.remainingCount >= 60 else {
            throw ParseError.tooShort
        }

        let formatCode = scanner.read(1).trimmed
        guard formatCode == "M" else {
            throw ParseError.invalidFormatCode(formatCode)
        }

        let legsText = scanner.read(1).trimmed
        guard let numberOfLegs = Int(legsText) else {
            throw ParseError.invalidNumberOfLegs(legsText)
        }

        let passengerName = Self.parsePassengerName(scanner.read(20))
        let electronicTicketIndicator = scanner.read(1).trimmed
        let operatingCarrierPNR = scanner.read(7).trimmed
        let fromAirport = scanner.read(3).trimmed
        let toAirport = scanner.read(3).trimmed
        let operatingCarrierDesignator = scanner.read(3).trimmed
        let flightNumber = scanner.read(5).trimmed
        let flightDateText = scanner.read(3).trimmed

        guard let flightDateJulian = Int(flightDateText) else {
            throw ParseError.invalidFlightDate(flightDateText)
        }

        self.rawValue = rawValue
        self.formatCode = formatCode
        self.numberOfLegs = numberOfLegs
        self.passengerName = passengerName
        self.electronicTicketIndicator = electronicTicketIndicator
        self.operatingCarrierPNR = operatingCarrierPNR
        self.fromAirport = fromAirport
        self.toAirport = toAirport
        self.operatingCarrierDesignator = operatingCarrierDesignator
        self.flightNumber = flightNumber
        self.flightDateJulian = flightDateJulian
        self.flightDate = Self.isoString(
            from: Self.flightDate(fromJulianDay: flightDateJulian, in: flightDateYear) ?? Self.todayAt1430()
        )
        self.compartmentCode = scanner.read(1).trimmed
        self.seatNumber = scanner.read(4).trimmed
        self.checkInSequenceNumber = scanner.read(5).trimmed
        self.passengerStatus = scanner.read(1).trimmed
    }

    var route: String {
        "\(fromAirport)-\(toAirport)"
    }

    var flightCode: String {
        "\(operatingCarrierDesignator)\(flightNumber)"
    }

    var summary: String {
        "\(flightCode) \(route)"
    }

    private static func flightDate(
        fromJulianDay julianDay: Int,
        in year: Int = Calendar.current.component(.year, from: Date())
    ) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let firstDayOfYear = DateComponents(year: year, month: 1, day: 1)

        guard let date = calendar.date(from: firstDayOfYear) else {
            return nil
        }

        guard let flightDay = calendar.date(byAdding: .day, value: julianDay - 1, to: date) else {
            return nil
        }

        return calendar.date(
            bySettingHour: 14,
            minute: 30,
            second: 0,
            of: flightDay
        )
    }

    private static func todayAt1430() -> Date {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: 14,
            minute: 30,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    private static func isoString(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func parsePassengerName(_ text: String) -> PassengerName {
        let parts = text
            .trimmed
            .split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            .map { String($0).trimmed }

        return PassengerName(
            surname: parts.first ?? "",
            givenName: parts.count > 1 ? parts[1] : ""
        )
    }
}

private final class FixedWidthScanner {
    private let value: String
    private var index: String.Index

    init(_ value: String) {
        self.value = value
        self.index = value.startIndex
    }

    var remainingCount: Int {
        value.distance(from: index, to: value.endIndex)
    }

    func read(_ count: Int) -> String {
        let endIndex = value.index(index, offsetBy: count, limitedBy: value.endIndex) ?? value.endIndex
        let text = String(value[index..<endIndex])
        index = endIndex
        return text
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
