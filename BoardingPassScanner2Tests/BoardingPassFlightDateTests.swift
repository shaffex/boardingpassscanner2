//
//  BoardingPassFlightDateTests.swift
//  BoardingPassScanner2Tests
//
//  Created by Peter Popovec on 11/05/2026.
//

import Foundation
import Testing
@testable import BoardingPassScanner2

struct BoardingPassFlightDateTests {
    @Test func flightDateUsesJulianDayInCurrentYear() throws {
        let referenceDate = referenceDate(year: 2026, month: 5, day: 20)
        let boardingPass = try BoardingPass(
            parsing: boardingPassText(julianDay: 131),
            referenceDate: referenceDate
        )

        #expect(boardingPass.flightDateJulian == 131)
        #expect(boardingPass.flightDate == expectedISODate(julianDay: 131, year: 2026))
    }

    @Test func flightDateConvertsFirstJulianDayToFirstDayOfExplicitYear() throws {
        let boardingPass = try BoardingPass(
            parsing: boardingPassText(julianDay: 1),
            flightDateYear: 2026
        )

        #expect(boardingPass.flightDateJulian == 1)
        #expect(boardingPass.flightDate == expectedISODate(julianDay: 1, year: 2026))
    }

    @Test func flightDateIsISO8601Formatted() throws {
        let boardingPass = try BoardingPass(
            parsing: boardingPassText(julianDay: 132),
            referenceDate: referenceDate(year: 2026, month: 5, day: 20)
        )

        #expect(ISO8601DateFormatter().date(from: boardingPass.flightDate) != nil)
    }

    @Test func fifthJulianDayUsesJanuaryFifthISODate() throws {
        let boardingPass = try BoardingPass(
            parsing: boardingPassText(julianDay: 5),
            flightDateYear: 2026
        )

        #expect(boardingPass.flightDate.hasPrefix("2026-01-05T"))
        #expect(boardingPass.flightDate.hasSuffix("Z"))
    }

    @Test func fixedYearConvertsFifthJulianDayToExactISODate() throws {
        let boardingPass = try BoardingPass(
            parsing: boardingPassText(julianDay: 5),
            flightDateYear: 2026
        )

        #expect(boardingPass.flightDate == "2026-01-05T14:30:00Z")
    }

    @Test func fixedYearConvertsSixtyFirstJulianDayToExactISODate() throws {
        let boardingPass = try BoardingPass(
            parsing: boardingPassText(julianDay: 61),
            flightDateYear: 2026
        )

        #expect(boardingPass.flightDate == "2026-03-02T14:30:00Z")
    }

    @Test func pastJulianDayBeyondThresholdUsesNextYear() throws {
        let boardingPass = try BoardingPass(
            parsing: boardingPassText(julianDay: 5),
            referenceDate: referenceDate(year: 2026, month: 5, day: 26),
            pastDateRolloverThresholdDays: 30
        )

        #expect(boardingPass.flightDate == "2027-01-05T14:30:00Z")
    }

    @Test func pastJulianDayInsideThresholdKeepsCurrentYear() throws {
        let boardingPass = try BoardingPass(
            parsing: boardingPassText(julianDay: 131),
            referenceDate: referenceDate(year: 2026, month: 5, day: 26),
            pastDateRolloverThresholdDays: 30
        )

        #expect(boardingPass.flightDate == expectedISODate(julianDay: 131, year: 2026))
    }

    @Test func explicitYearDoesNotRollOverPastJulianDay() throws {
        let boardingPass = try BoardingPass(
            parsing: boardingPassText(julianDay: 5),
            flightDateYear: 2026,
            referenceDate: referenceDate(year: 2026, month: 5, day: 26),
            pastDateRolloverThresholdDays: 30
        )

        #expect(boardingPass.flightDate == "2026-01-05T14:30:00Z")
    }

    private func boardingPassText(julianDay: Int) -> String {
        "M" +
        "1" +
        fixedWidth("DATE/TEST", length: 20) +
        "E" +
        fixedWidth("ABC123", length: 7) +
        "ATH" +
        "TLV" +
        fixedWidth("LY", length: 3) +
        fixedWidth("0546", length: 5) +
        String(format: "%03d", julianDay) +
        "Y" +
        "045C" +
        fixedWidth("0109", length: 5) +
        "1" +
        "00"
    }

    private func expectedISODate(julianDay: Int, year: Int) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let firstDayOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let flightDay = calendar.date(byAdding: .day, value: julianDay - 1, to: firstDayOfYear)!
        let date = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: flightDay)!

        return ISO8601DateFormatter().string(from: date)
    }

    private func referenceDate(year: Int, month: Int, day: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(year: year, month: month, day: day, hour: 12)
        )!
    }

    private func fixedWidth(_ value: String, length: Int) -> String {
        let truncated = String(value.prefix(length))
        return truncated.padding(toLength: length, withPad: " ", startingAt: 0)
    }
}
