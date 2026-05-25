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
        guard let item = item(in: dataModelAirlinesKey, matchingCode: code) else {
            return nil
        }

        return Airline(
            code: code,
            name: stringValue(item, "name"),
            country: stringValue(item, "country")
        )
    }

    static func airport(for code: String) -> Airport? {
        guard let item = item(in: dataModelAirportsKey, matchingCode: code) else {
            return nil
        }

        return Airport(
            code: code,
            name: stringValue(item, "name"),
            city: stringValue(item, "city"),
            country: stringValue(item, "country")
        )
    }

    static func airlineName(for code: String) -> String {
        airline(for: code)?.name ?? code
    }

    static func airportName(for code: String) -> String {
        airport(for: code)?.name ?? code
    }

    private static func item(in dataModelKey: String, matchingCode code: String) -> SxDataModelItem? {
        guard !code.isEmpty,
              let model = SxMagicVariables.shared.value(forKey: dataModelKey) as? SxDataModel else {
            return nil
        }

        let needle = code.uppercased()
        return model.items.first { item in
            (item.item["code"] as? String)?.uppercased() == needle
        }
    }

    private static func stringValue(_ item: SxDataModelItem, _ key: String) -> String {
        (item.item[key] as? String) ?? ""
    }
}
