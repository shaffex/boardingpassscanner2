//
//  MigrationAssistant.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 13/05/2026.
//

import MagicUiFramework

struct MigrationAssistant {
    static func checkMigration() {
        let nsDefaultsV1 = NsDefaultsV1()
        if let settings = nsDefaultsV1.loadSettings() {
            //nsDefaultsV1.deleteSettings()
            
            if settings.myBoardingPassesArray.isEmpty {
                print("No boarding passes to migrate (empty")
            }
            
            let newItems: [SxDataModelItem] = settings.myBoardingPassesArray.compactMap { barcode in
                guard let boardingPass = try? BoardingPass(parsing: barcode.barcodeText) else {
                    return nil
                }

                return SxDataModelItem(item: [
                    "name": boardingPass.passengerName.displayName,
                    "text": barcode.barcodeText,
                    "type": barcode.barcodeType,
                    "flightDate": barcode.barcodeDepartureDate,
                    "summary": boardingPass.summary
                ])
            }
            
            if let sxDataModel = SxMagicVariables.shared.value(forKey: "dataModelMyCodes") as? SxDataModel {
                
//                let newItems = settings.myBoardingPassesArray.map { barcode in
//                    try? BoardingPass(parsing: barcode.barcodeText)
//                    SxDataModelItem(item: ["name":  text":barcode.barcodeText, "type":barcode.barcodeType])
//                }

                sxDataModel.items.append(contentsOf: newItems)
            }
        }
    }
}
