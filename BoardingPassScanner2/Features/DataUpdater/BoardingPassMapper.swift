//
//  BoardingPassMapper.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import Foundation
import MagicUiFramework

struct BoardingPassMapper {
    static let dataModelAirlinesKey = "dataModelAirlines"
    static let dataModelAirportsKey = "dataModelAirports"

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
        guard !code.isEmpty, let index = airlineIndex() else { return nil }
        return index[code.uppercased()]
    }

    static func airport(for code: String) -> Airport? {
        guard !code.isEmpty, let index = airportIndex() else { return nil }
        return index[code.uppercased()]
    }

    static func airlineName(for code: String) -> String {
        airline(for: code)?.name ?? code
    }

    static func airportName(for code: String) -> String {
        airport(for: code)?.name ?? code
    }

    private static var airlineCache: (modelID: ObjectIdentifier, itemCount: Int, index: [String: Airline])?
    private static var airportCache: (modelID: ObjectIdentifier, itemCount: Int, index: [String: Airport])?

    private static func airlineIndex() -> [String: Airline]? {
        guard let model = SxMagicVariables.shared.value(forKey: dataModelAirlinesKey) as? SxDataModel else {
            airlineCache = nil
            return nil
        }
        let id = ObjectIdentifier(model)
        if let cached = airlineCache, cached.modelID == id, cached.itemCount == model.items.count {
            return cached.index
        }
        var index: [String: Airline] = [:]
        index.reserveCapacity(model.items.count)
        for item in model.items {
            guard let code = item.item["code"] as? String, !code.isEmpty else { continue }
            index[code.uppercased()] = Airline(
                code: code,
                name: stringValue(item, "name"),
                country: stringValue(item, "country")
            )
        }
        airlineCache = (id, model.items.count, index)
        return index
    }

    private static func airportIndex() -> [String: Airport]? {
        guard let model = SxMagicVariables.shared.value(forKey: dataModelAirportsKey) as? SxDataModel else {
            airportCache = nil
            return nil
        }
        let id = ObjectIdentifier(model)
        if let cached = airportCache, cached.modelID == id, cached.itemCount == model.items.count {
            return cached.index
        }
        var index: [String: Airport] = [:]
        index.reserveCapacity(model.items.count)
        for item in model.items {
            guard let code = item.item["code"] as? String, !code.isEmpty else { continue }
            index[code.uppercased()] = Airport(
                code: code,
                name: stringValue(item, "name"),
                city: stringValue(item, "city"),
                country: stringValue(item, "country")
            )
        }
        airportCache = (id, model.items.count, index)
        return index
    }

    private static func stringValue(_ item: SxDataModelItem, _ key: String) -> String {
        (item.item[key] as? String) ?? ""
    }
}
