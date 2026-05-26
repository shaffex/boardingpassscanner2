//
//  MigrationAssistant.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 13/05/2026.
//

import Foundation

struct MigrationAssistant {
    @MainActor
    static func checkMigration() {
        let nsDefaultsV1 = NsDefaultsV1()
        guard let settings = nsDefaultsV1.loadSettings() else {
            return
        }

        if settings.myBoardingPassesArray.isEmpty {
            print("No boarding passes to migrate (empty)")
            return
        }

        let store = BoardingPassStore.shared
        for barcode in settings.myBoardingPassesArray {
            store.insertIfMissing(
                barcodeText: barcode.barcodeText,
                barcodeType: barcode.barcodeType,
                flightDateYear: barcode.flightDateYear
            )
        }
    }
}
