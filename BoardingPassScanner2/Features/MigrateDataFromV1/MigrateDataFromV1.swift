//
//  MigrateDataFromV1.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 12/05/2026.
//

import Foundation
import MagicUiFramework

struct MigrateDataFromV1 {
    func readTextFileFromResource(named fileName: String, withExtension fileExtension: String) -> String? {
        guard let url = Bundle.main.url(
            forResource: fileName,
            withExtension: fileExtension
        ) else {
            print("Resource not found: \(fileName).\(fileExtension)")
            return nil
        }

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Failed to read resource:", error)
            return nil
        }
    }

    @MainActor
    public func importBarcodes(jsonString: String) {
        print("importBarcodes:", jsonString)

        do {
            let importedBarcodes = try JSONDecoder().decode([BoardingPassBarcodeV1].self, from: Data(jsonString.utf8))

            let store = BoardingPassStore.shared
            for barcode in importedBarcodes {
                store.insertIfMissing(
                    barcodeText: barcode.barcodeText,
                    barcodeType: barcode.barcodeType,
                    flightDateYear: barcode.flightDateYear
                )
            }

            print("Import completed, \(importedBarcodes.count) barcodes imported")
        } catch {
            print("Error=", error.localizedDescription)
            return
        }

        print("Json decoding passed")
    }

    @MainActor
    func importFromResource(named: String, withExtension: String) {
        if let jsonString = readTextFileFromResource(named: named, withExtension: withExtension) {
            importBarcodes(jsonString: jsonString)
        }
    }
}

struct Action_importFromV1: SxActionProtocol {
    let node: MagicNode?

    func execute(_ actionString: String) {
        Task { @MainActor in
            MigrateDataFromV1().importFromResource(named: "ExportedBoardingPasses", withExtension: "json")
        }
    }
}
