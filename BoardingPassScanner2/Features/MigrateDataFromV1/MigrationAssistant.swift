//
//  MigrationAssistant.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 13/05/2026.
//

import Foundation

struct MigrationAssistant {
    private static let migratedKey = "v1MigrationCompleted"

    @MainActor
    static func checkMigration() {
        guard !UserDefaults.standard.bool(forKey: migratedKey) else { return }

        let nsDefaultsV1 = NsDefaultsV1()
        guard let settings = nsDefaultsV1.loadSettings() else {
            UserDefaults.standard.set(true, forKey: migratedKey)
            return
        }

        if !settings.myBoardingPassesArray.isEmpty {
            let store = BoardingPassStore.shared
            for barcode in settings.myBoardingPassesArray {
                store.insertIfMissing(
                    barcodeText: barcode.barcodeText,
                    barcodeType: barcode.barcodeType,
                    flightDateYear: barcode.flightDateYear
                )
            }
        }

        UserDefaults.standard.set(true, forKey: migratedKey)
    }
}
