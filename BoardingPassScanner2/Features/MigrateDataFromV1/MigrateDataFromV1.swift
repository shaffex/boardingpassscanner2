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
                
                let newItems: [SxDataModelItem] = importedBarcodes.compactMap { barcode in
                    guard let boardingPass = try? BoardingPass(parsing: barcode.barcodeText) else {
                        return nil
                    }

                    let airline = BoardingPassMapper.airline(for: boardingPass.operatingCarrierDesignator)
                    let fromAirport = BoardingPassMapper.airport(for: boardingPass.fromAirport)
                    let toAirport = BoardingPassMapper.airport(for: boardingPass.toAirport)
                    
                    return SxDataModelItem(item: [
                        "name": boardingPass.passengerName.displayName,
                        "text": barcode.barcodeText,
                        "type": barcode.barcodeType,
                        "flightDate": barcode.barcodeDepartureDate,
                        "summary": boardingPass.summary,
                        "fromAirport": boardingPass.fromAirport,
                        "fromAirportCity": fromAirport?.city ?? "",
                        "toAirport": boardingPass.toAirport,
                        "toAirportCity": toAirport?.city ?? "",
                        "airline": airline?.name ?? "",
                        "flightCode": boardingPass.operatingCarrierDesignator,
                        "flightNumber": boardingPass.flightNumber,
                    ])
                }

                sxDataModel.items.append(contentsOf: newItems)
            }
            
            print("Import completed, \(importedBarcodes.count) barcodes imported")
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

    func importFromResource(named: String, withExtension: String) {
        
        
        if let jsonString = readTextFileFromResource(named: named, withExtension: withExtension) {
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
        MigrateDataFromV1().importFromResource(named: "ExportedBoardingPasses", withExtension: "json")
    }
}
