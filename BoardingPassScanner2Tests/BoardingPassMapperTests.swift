//
//  BoardingPassMapperTests.swift
//  BoardingPassScanner2Tests
//
//  Created by Peter Popovec on 24/05/2026.
//

import MagicUiFramework
import Testing
@testable import BoardingPassScanner2

@MainActor
struct BoardingPassMapperTests {
    @Test func airlineReturnsMatchingEntry() {
        installAirlines([
            ["code": "FR", "name": "Ryanair", "country": "Ireland"],
            ["code": "LY", "name": "El Al", "country": "Israel"]
        ])

        let airline = BoardingPassMapper.airline(for: "FR")

        #expect(airline?.code == "FR")
        #expect(airline?.name == "Ryanair")
        #expect(airline?.country == "Ireland")
    }

    @Test func airlineMatchesCodeCaseInsensitively() {
        installAirlines([
            ["code": "FR", "name": "Ryanair", "country": "Ireland"]
        ])

        #expect(BoardingPassMapper.airline(for: "fr")?.name == "Ryanair")
    }

    @Test func airlineReturnsNilForUnknownCode() {
        installAirlines([
            ["code": "FR", "name": "Ryanair", "country": "Ireland"]
        ])

        #expect(BoardingPassMapper.airline(for: "ZZ") == nil)
    }

    @Test func airlineReturnsNilForEmptyCode() {
        installAirlines([
            ["code": "FR", "name": "Ryanair", "country": "Ireland"]
        ])

        #expect(BoardingPassMapper.airline(for: "") == nil)
    }

    @Test func airlineReturnsNilWhenDataModelMissing() {
        clearDataModel(key: BoardingPassMapper.dataModelAirlinesKey)

        #expect(BoardingPassMapper.airline(for: "FR") == nil)
    }

    @Test func airlineNameFallsBackToCodeWhenNotFound() {
        installAirlines([
            ["code": "FR", "name": "Ryanair", "country": "Ireland"]
        ])

        #expect(BoardingPassMapper.airlineName(for: "ZZ") == "ZZ")
    }

    @Test func airlineNameReturnsResolvedNameWhenFound() {
        installAirlines([
            ["code": "FR", "name": "Ryanair", "country": "Ireland"]
        ])

        #expect(BoardingPassMapper.airlineName(for: "FR") == "Ryanair")
    }

    @Test func airportReturnsMatchingEntry() {
        installAirports([
            ["code": "ATH", "name": "Athens Intl", "city": "Athens", "country": "Greece"],
            ["code": "TLV", "name": "Ben Gurion", "city": "Tel Aviv", "country": "Israel"]
        ])

        let airport = BoardingPassMapper.airport(for: "TLV")

        #expect(airport?.code == "TLV")
        #expect(airport?.name == "Ben Gurion")
        #expect(airport?.city == "Tel Aviv")
        #expect(airport?.country == "Israel")
    }

    @Test func airportMatchesCodeCaseInsensitively() {
        installAirports([
            ["code": "ATH", "name": "Athens Intl", "city": "Athens", "country": "Greece"]
        ])

        #expect(BoardingPassMapper.airport(for: "ath")?.name == "Athens Intl")
    }

    @Test func airportReturnsNilForUnknownCode() {
        installAirports([
            ["code": "ATH", "name": "Athens Intl", "city": "Athens", "country": "Greece"]
        ])

        #expect(BoardingPassMapper.airport(for: "XXX") == nil)
    }

    @Test func airportReturnsNilWhenDataModelMissing() {
        clearDataModel(key: BoardingPassMapper.dataModelAirportsKey)

        #expect(BoardingPassMapper.airport(for: "ATH") == nil)
    }

    @Test func airportNameFallsBackToCodeWhenNotFound() {
        installAirports([
            ["code": "ATH", "name": "Athens Intl", "city": "Athens", "country": "Greece"]
        ])

        #expect(BoardingPassMapper.airportName(for: "XXX") == "XXX")
    }

    @Test func airportNameReturnsResolvedNameWhenFound() {
        installAirports([
            ["code": "ATH", "name": "Athens Intl", "city": "Athens", "country": "Greece"]
        ])

        #expect(BoardingPassMapper.airportName(for: "ATH") == "Athens Intl")
    }

    @discardableResult
    private func installAirlines(_ rows: [[String: String]]) -> SxDataModel {
        installDataModel(key: BoardingPassMapper.dataModelAirlinesKey, rows: rows)
    }

    @discardableResult
    private func installAirports(_ rows: [[String: String]]) -> SxDataModel {
        installDataModel(key: BoardingPassMapper.dataModelAirportsKey, rows: rows)
    }

    private func installDataModel(key: String, rows: [[String: String]]) -> SxDataModel {
        let model = SxDataModel(name: key, type: .embedded)
        model.items = rows.map { row in
            SxDataModelItem(item: row.reduce(into: [String: Any]()) { result, entry in
                result[entry.key] = entry.value
            })
        }
        SxMagicVariables.shared.setValue(model, forKey: key)
        return model
    }

    private func clearDataModel(key: String) {
        SxMagicVariables.shared.setValue(nil, forKey: key)
    }
}
