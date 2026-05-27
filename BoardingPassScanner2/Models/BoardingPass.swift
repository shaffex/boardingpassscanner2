//
//  BoardingPass.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 11/05/2026.
//

import Foundation

enum BoardingPassConfig {
    // If an inferred Julian flight date is more than this many days in the past,
    // treat it as next year's flight. Imported passes with an explicit year skip this rollover.
    static let pastJulianDateRolloverThresholdDays = 30
}

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
    let legs: [Leg]
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

    struct Leg: Equatable {
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

        var route: String {
            "\(fromAirport)-\(toAirport)"
        }

        var flightCode: String {
            "\(operatingCarrierDesignator)\(flightNumber)"
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
        flightDateYear: Int? = nil,
        referenceDate: Date = Date(),
        pastDateRolloverThresholdDays: Int = BoardingPassConfig.pastJulianDateRolloverThresholdDays
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

        let flightDate = Self.isoString(
            from: Self.flightDate(
                fromJulianDay: flightDateJulian,
                explicitYear: flightDateYear,
                referenceDate: referenceDate,
                pastDateRolloverThresholdDays: pastDateRolloverThresholdDays
            ) ?? Self.todayAt1430()
        )
        let compartmentCode = scanner.read(1).trimmed
        let seatNumber = scanner.read(4).trimmed
        let checkInSequenceNumber = scanner.read(5).trimmed
        let passengerStatus = scanner.read(1).trimmed
        let firstLeg = Leg(
            operatingCarrierPNR: operatingCarrierPNR,
            fromAirport: fromAirport,
            toAirport: toAirport,
            operatingCarrierDesignator: operatingCarrierDesignator,
            flightNumber: flightNumber,
            flightDateJulian: flightDateJulian,
            flightDate: flightDate,
            compartmentCode: compartmentCode,
            seatNumber: seatNumber,
            checkInSequenceNumber: checkInSequenceNumber,
            passengerStatus: passengerStatus
        )

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
        self.flightDate = flightDate
        self.compartmentCode = compartmentCode
        self.seatNumber = seatNumber
        self.checkInSequenceNumber = checkInSequenceNumber
        self.passengerStatus = passengerStatus
        self.legs = [firstLeg] + Self.parseAdditionalLegs(
            in: rawValue,
            startingAt: 58,
            explicitYear: flightDateYear,
            referenceDate: referenceDate,
            pastDateRolloverThresholdDays: pastDateRolloverThresholdDays
        )
    }

    var route: String {
        "\(fromAirport)-\(toAirport)"
    }

    var flightCode: String {
        "\(operatingCarrierDesignator)\(flightNumber)"
    }

    private static func parseAdditionalLegs(
        in rawValue: String,
        startingAt startOffset: Int,
        explicitYear: Int?,
        referenceDate: Date,
        pastDateRolloverThresholdDays: Int
    ) -> [Leg] {
        var legs: [Leg] = []
        var offset = startOffset

        while offset + 35 <= rawValue.count {
            if let leg = parseLeg(
                in: rawValue,
                at: offset,
                explicitYear: explicitYear,
                referenceDate: referenceDate,
                pastDateRolloverThresholdDays: pastDateRolloverThresholdDays
            ) {
                legs.append(leg)
                offset += 35
            } else {
                offset += 1
            }
        }

        return legs
    }

    private static func parseLeg(
        in rawValue: String,
        at offset: Int,
        explicitYear: Int?,
        referenceDate: Date,
        pastDateRolloverThresholdDays: Int
    ) -> Leg? {
        let scanner = FixedWidthScanner(rawValue, offset: offset)

        guard scanner.remainingCount >= 35 else {
            return nil
        }

        let pnr = scanner.read(7).trimmed
        let fromAirport = scanner.read(3).trimmed
        let toAirport = scanner.read(3).trimmed
        let carrier = scanner.read(3).trimmed
        let flightNumber = scanner.read(5).trimmed
        let flightDateText = scanner.read(3).trimmed
        let compartmentCode = scanner.read(1).trimmed
        let seatNumber = scanner.read(4).trimmed
        let sequenceNumber = scanner.read(5).trimmed
        let passengerStatus = scanner.read(1).trimmed

        guard
            !pnr.isEmpty,
            isAirportCode(fromAirport),
            isAirportCode(toAirport),
            isCarrierDesignator(carrier),
            !flightNumber.isEmpty,
            let flightDateJulian = Int(flightDateText),
            (1...366).contains(flightDateJulian)
        else {
            return nil
        }

        let flightDate = Self.isoString(
            from: Self.flightDate(
                fromJulianDay: flightDateJulian,
                explicitYear: explicitYear,
                referenceDate: referenceDate,
                pastDateRolloverThresholdDays: pastDateRolloverThresholdDays
            ) ?? Self.todayAt1430()
        )

        return Leg(
            operatingCarrierPNR: pnr,
            fromAirport: fromAirport,
            toAirport: toAirport,
            operatingCarrierDesignator: carrier,
            flightNumber: flightNumber,
            flightDateJulian: flightDateJulian,
            flightDate: flightDate,
            compartmentCode: compartmentCode,
            seatNumber: seatNumber,
            checkInSequenceNumber: sequenceNumber,
            passengerStatus: passengerStatus
        )
    }

    private static func isAirportCode(_ value: String) -> Bool {
        value.count == 3 && value.allSatisfy { $0.isLetter }
    }

    private static func isCarrierDesignator(_ value: String) -> Bool {
        (2...3).contains(value.count) && value.allSatisfy { $0.isLetter || $0.isNumber }
    }

    private static func flightDate(
        fromJulianDay julianDay: Int,
        explicitYear: Int?,
        referenceDate: Date,
        pastDateRolloverThresholdDays: Int
    ) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: referenceDate)

        if let explicitYear {
            return flightDate(fromJulianDay: julianDay, in: explicitYear)
        }

        guard let candidateDate = flightDate(fromJulianDay: julianDay, in: currentYear) else {
            return nil
        }

        let candidateDay = calendar.startOfDay(for: candidateDate)
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let daysInPast = calendar.dateComponents([.day], from: candidateDay, to: referenceDay).day ?? 0

        if daysInPast > pastDateRolloverThresholdDays {
            return flightDate(fromJulianDay: julianDay, in: currentYear + 1)
        }

        return candidateDate
    }

    private static func flightDate(
        fromJulianDay julianDay: Int,
        in year: Int
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

    init(_ value: String, offset: Int = 0) {
        self.value = value
        self.index = value.index(
            value.startIndex,
            offsetBy: min(offset, value.count),
            limitedBy: value.endIndex
        ) ?? value.endIndex
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
