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
        let boardingPass = try BoardingPass(parsing: boardingPassText(julianDay: 131))

        #expect(boardingPass.flightDateJulian == 131)
        #expect(boardingPass.flightDate == expectedISODate(julianDay: 131))
    }

    @Test func flightDateConvertsFirstJulianDayToFirstDayOfCurrentYear() throws {
        let boardingPass = try BoardingPass(parsing: boardingPassText(julianDay: 1))

        #expect(boardingPass.flightDateJulian == 1)
        #expect(boardingPass.flightDate == expectedISODate(julianDay: 1))
    }

    @Test func flightDateIsISO8601Formatted() throws {
        let boardingPass = try BoardingPass(parsing: boardingPassText(julianDay: 132))

        #expect(ISO8601DateFormatter().date(from: boardingPass.flightDate) != nil)
    }

    @Test func fifthJulianDayUsesJanuaryFifthISODate() throws {
        let boardingPass = try BoardingPass(parsing: boardingPassText(julianDay: 5))
        let year = Calendar.current.component(.year, from: Date())

        #expect(boardingPass.flightDate.hasPrefix("\(year)-01-05T"))
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

    private func expectedISODate(julianDay: Int) -> String {
        let year = Calendar.current.component(.year, from: Date())
        let calendar = Calendar(identifier: .gregorian)
        let firstDayOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let flightDay = calendar.date(byAdding: .day, value: julianDay - 1, to: firstDayOfYear)!
        let date = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: flightDay)!

        return ISO8601DateFormatter().string(from: date)
    }

    private func fixedWidth(_ value: String, length: Int) -> String {
        let truncated = String(value.prefix(length))
        return truncated.padding(toLength: length, withPad: " ", startingAt: 0)
    }
}
