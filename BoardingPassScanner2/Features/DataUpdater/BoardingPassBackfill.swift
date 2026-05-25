//
//  BoardingPassBackfill.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import Foundation
import MagicUiFramework

struct BoardingPassBackfill {
    private static let myCodesKey = "dataModelMyCodes"
    private static let backfillRequiredKeys = ["formatCode", "numberOfLegs"]

    @MainActor
    static func backfillMissingFields() {
        guard let model = SxMagicVariables.shared.value(forKey: myCodesKey) as? SxDataModel else {
            return
        }

        var didChange = false

        for index in model.items.indices {
            let existing = model.items[index].item

            guard needsBackfill(existing) else { continue }
            guard let text = existing["text"] as? String, !text.isEmpty else { continue }

            let barcodeType = existing["type"] as? String ?? "Boarding pass"
            let scannedDate = existing["scannedDate"] as? String ?? ISO8601DateFormatter().string(from: Date())
            let enriched = Action_addNewBoardingPass.itemData(
                for: text,
                barcodeType: barcodeType,
                scannedDate: scannedDate
            )

            var merged: [String: Any] = existing
            for (key, value) in enriched where merged[key] == nil || (merged[key] as? String)?.isEmpty == true {
                merged[key] = value
            }

            model.items[index] = SxDataModelItem(item: merged)
            didChange = true
        }

        if didChange {
            print("[BoardingPassBackfill] Backfilled missing fields on saved boarding passes")
        }
    }

    private static func needsBackfill(_ item: [String: Any]) -> Bool {
        backfillRequiredKeys.contains { key in
            (item[key] as? String)?.isEmpty != false
        }
    }
}
