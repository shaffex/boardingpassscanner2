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
    
    public func importBarcodes(jsonString: String) {
        print("importBarcodes:", jsonString)
        var importedBarcodes: [BoardingPassBarcodeV1] = []
        do {
            importedBarcodes = try JSONDecoder().decode([BoardingPassBarcodeV1].self, from: Data(jsonString.utf8))
            
            if let sxDataModel = SxMagicVariables.shared.value(forKey: "dataModelMyCodes") as? SxDataModel {
                let newItems = importedBarcodes.map { barcode in
                    SxDataModelItem(item: ["text":barcode.barcodeText, "type":barcode.barcodeType])
                }

                sxDataModel.items.append(contentsOf: newItems)
            }
            
            print("KKC")
        }
        catch {
            print("Error=",error.localizedDescription)
//            UtilsUi.showBannerError(title: "Error", subtitle: "File format is not in a valid Boarding Pass Scanner format for importing barcodes.")
            return
        }
        
        print("Json decoding passed")
        
//        for importedBoardingPass in imporetBarcodes {
//            if ((importedBoardingPass.barcodeText == "" || importedBoardingPass.barcodeType == "")) {
//                UtilsUi.showBannerError(title: "Error", subtitle: "File format is not in a valid Boarding Pass Scanner format for importing barcodes.")
//                return
//            }
//            importToMyBoardingPasses(importedBoardingPass)
//        }
//        saveSettings()
//        
//        UtilsUi.showBannerInfo(title: "Import Status", subtitle: "\n\(imporetBarcodes.count) boarding passes imported successfully.")
    }

    func xxx() {
        
        
        if let jsonString = readTextFileFromResource(named: "ExportedBoardingPasses", withExtension: "json") {
            importBarcodes(jsonString: jsonString)
        }
    }
    
    
    func migrateDateFromNsDefaultsV1() {
        //if let UserDefaults.standard.object(forKey: "settings")
    }
    
}

// temp only
import MagicUiFramework
struct Action_importFromV1: SxActionProtocol {
    let node: MagicNode?
    
    func execute(_ actionString: String) {
        MigrateDataFromV1().xxx()
    }
}
