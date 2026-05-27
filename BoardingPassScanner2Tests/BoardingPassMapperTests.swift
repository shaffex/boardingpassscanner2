//
//  BoardingPassMapperTests.swift
//  BoardingPassScanner2Tests
//
//  Created by Peter Popovec on 24/05/2026.
//

import Foundation
import Testing
@testable import BoardingPassScanner2

@MainActor
struct BoardingPassMapperTests {
    init() {
        BoardingPassMapper.resetForTesting()
    }

    @Test func airlineReturnsMatchingEntry() {
        installAirlines([
            .init(code: "FR", name: "Ryanair", country: "Ireland"),
            .init(code: "LY", name: "El Al", country: "Israel")
        ])

        let airline = BoardingPassMapper.airline(for: "FR")

        #expect(airline?.code == "FR")
        #expect(airline?.name == "Ryanair")
        #expect(airline?.country == "Ireland")
    }

    @Test func airlineMatchesCodeCaseInsensitively() {
        installAirlines([
            .init(code: "FR", name: "Ryanair", country: "Ireland")
        ])

        #expect(BoardingPassMapper.airline(for: "fr")?.name == "Ryanair")
    }

    @Test func airlineReturnsNilForUnknownCode() {
        installAirlines([
            .init(code: "FR", name: "Ryanair", country: "Ireland")
        ])

        #expect(BoardingPassMapper.airline(for: "ZZ") == nil)
    }

    @Test func airlineReturnsNilForEmptyCode() {
        installAirlines([
            .init(code: "FR", name: "Ryanair", country: "Ireland")
        ])

        #expect(BoardingPassMapper.airline(for: "") == nil)
    }

    @Test func airlineReturnsNilWhenDatabaseEmpty() {
        BoardingPassMapper.resetForTesting()
        BoardingPassMapper.installForTesting(airlines: [], airports: [])

        #expect(BoardingPassMapper.airline(for: "FR") == nil)
    }

    @Test func airlineNameFallsBackToCodeWhenNotFound() {
        installAirlines([
            .init(code: "FR", name: "Ryanair", country: "Ireland")
        ])

        #expect(BoardingPassMapper.airlineName(for: "ZZ") == "ZZ")
    }

    @Test func airlineNameReturnsResolvedNameWhenFound() {
        installAirlines([
            .init(code: "FR", name: "Ryanair", country: "Ireland")
        ])

        #expect(BoardingPassMapper.airlineName(for: "FR") == "Ryanair")
    }

    @Test func airportReturnsMatchingEntry() {
        installAirports([
            .init(code: "ATH", name: "Athens Intl", city: "Athens", country: "Greece"),
            .init(code: "TLV", name: "Ben Gurion", city: "Tel Aviv", country: "Israel")
        ])

        let airport = BoardingPassMapper.airport(for: "TLV")

        #expect(airport?.code == "TLV")
        #expect(airport?.name == "Ben Gurion")
        #expect(airport?.city == "Tel Aviv")
        #expect(airport?.country == "Israel")
    }

    @Test func airportMatchesCodeCaseInsensitively() {
        installAirports([
            .init(code: "ATH", name: "Athens Intl", city: "Athens", country: "Greece")
        ])

        #expect(BoardingPassMapper.airport(for: "ath")?.name == "Athens Intl")
    }

    @Test func airportReturnsNilForUnknownCode() {
        installAirports([
            .init(code: "ATH", name: "Athens Intl", city: "Athens", country: "Greece")
        ])

        #expect(BoardingPassMapper.airport(for: "XXX") == nil)
    }

    @Test func airportReturnsNilWhenDatabaseEmpty() {
        BoardingPassMapper.resetForTesting()
        BoardingPassMapper.installForTesting(airlines: [], airports: [])

        #expect(BoardingPassMapper.airport(for: "ATH") == nil)
    }

    @Test func airportNameFallsBackToCodeWhenNotFound() {
        installAirports([
            .init(code: "ATH", name: "Athens Intl", city: "Athens", country: "Greece")
        ])

        #expect(BoardingPassMapper.airportName(for: "XXX") == "XXX")
    }

    @Test func airportNameReturnsResolvedNameWhenFound() {
        installAirports([
            .init(code: "ATH", name: "Athens Intl", city: "Athens", country: "Greece")
        ])

        #expect(BoardingPassMapper.airportName(for: "ATH") == "Athens Intl")
    }

    @Test func airlineLookupPerformance() {
        let airlineCount = 1500
        let airlines = (0..<airlineCount).map { index in
            BoardingPassMapper.Airline(
                code: String(format: "A%04d", index),
                name: "Airline \(index)",
                country: "Country \(index % 200)"
            )
        }
        BoardingPassMapper.installForTesting(airlines: airlines, airports: [])

        let codes = (0..<1000).map { index in
            String(format: "A%04d", (index * 37) % airlineCount)
        }

        let start = ContinuousClock.now
        var hits = 0
        for code in codes {
            if BoardingPassMapper.airline(for: code) != nil {
                hits += 1
            }
        }
        let elapsed = ContinuousClock.now - start

        print("airlineLookupPerformance: \(hits) hits / \(codes.count) lookups over \(airlineCount) entries in \(elapsed)")
        #expect(hits == codes.count)
    }

    @Test func airportLookupPerformance() {
        let airportCount = 5000
        let airports = (0..<airportCount).map { index in
            BoardingPassMapper.Airport(
                code: String(format: "P%04d", index),
                name: "Airport \(index)",
                city: "City \(index)",
                country: "Country \(index % 200)"
            )
        }
        BoardingPassMapper.installForTesting(airlines: [], airports: airports)

        let codes = (0..<1000).map { index in
            String(format: "P%04d", (index * 37) % airportCount)
        }

        let start = ContinuousClock.now
        var hits = 0
        for code in codes {
            if BoardingPassMapper.airport(for: code) != nil {
                hits += 1
            }
        }
        let elapsed = ContinuousClock.now - start

        print("airportLookupPerformance: \(hits) hits / \(codes.count) lookups over \(airportCount) entries in \(elapsed)")
        #expect(hits == codes.count)
    }

    private func installAirlines(_ airlines: [BoardingPassMapper.Airline]) {
        BoardingPassMapper.installForTesting(airlines: airlines, airports: [])
    }

    private func installAirports(_ airports: [BoardingPassMapper.Airport]) {
        BoardingPassMapper.installForTesting(airlines: [], airports: airports)
    }
}
