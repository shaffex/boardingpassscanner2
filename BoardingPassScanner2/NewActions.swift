//
//  NewActions.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 15/05/2025.
//

import Foundation
import MagicUiFramework


struct Action_addNewBoardingPass: SxActionProtocol {
    let node: MagicNode?
    
    func barcodeType(_ str: String) -> String {
        actionParts(str).first?
            .replacingOccurrences(of: "type:", with: "") ?? ""
    }
    
    func barcodeText(_ str: String) -> String {
        guard actionParts(str).count > 1 else {
            return str
        }

        return actionParts(str)[1]
            .replacingOccurrences(of: "text:", with: "")
    }

    private func actionParts(_ str: String) -> [String] {
        str.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .map(String.init)
    }
    
    func execute(_ actionString: String) {
        let text = barcodeText(actionString)
        
        if isBoardingPassAlreadyPresent(text) {
            PluginActions.shared.runAction("presentAlert:myAlertBoardingPassAlreadyExists")
            return
        }
        
        guard (try? BoardingPass(parsing: text)) != nil else {
            PluginActions.shared.runAction("presentAlert:myAlertInvalidBoardingPassCode")
            return
        }
        
        if let sxDataModel = SxMagicVariables.shared.value(forKey: "dataModelMyCodes") as? SxDataModel {
            let item = SxDataModelItem(item: itemData(for: text, barcodeType: barcodeType(actionString)))
            sxDataModel.items.append(item)

        }
        
    }

    private func itemData(for barcodeText: String, barcodeType: String) -> [String: String] {
        Self.itemData(for: barcodeText, barcodeType: barcodeType, scannedDate: ISO8601DateFormatter().string(from: Date()))
    }

    static func itemData(for barcodeText: String, barcodeType: String, scannedDate: String) -> [String: String] {
        guard let boardingPass = try? BoardingPass(parsing: barcodeText) else {
            return [
                "name": "Unknown passenger",
                "text": barcodeText,
                "type": "Boarding pass",
                "scannedDate": scannedDate
            ]
        }

        let airline = BoardingPassMapper.airline(for: boardingPass.operatingCarrierDesignator)
        let fromAirport = BoardingPassMapper.airport(for: boardingPass.fromAirport)
        let toAirport = BoardingPassMapper.airport(for: boardingPass.toAirport)

        return [
            "name": boardingPass.passengerName.displayName,
            "text": barcodeText,
            "type": barcodeType,
            "scannedDate": scannedDate,
            "formatCode": boardingPass.formatCode,
            "numberOfLegs": String(boardingPass.numberOfLegs),
            "passengerSurname": boardingPass.passengerName.surname,
            "passengerGivenName": boardingPass.passengerName.givenName,
            "electronicTicketIndicator": boardingPass.electronicTicketIndicator,
            "pnr": boardingPass.operatingCarrierPNR,
            "fromAirport": boardingPass.fromAirport,
            "fromAirportName": fromAirport?.name ?? boardingPass.fromAirport,
            "fromAirportCity": fromAirport?.city ?? "",
            "fromAirportCountry": fromAirport?.country ?? "",
            "toAirport": boardingPass.toAirport,
            "toAirportName": toAirport?.name ?? boardingPass.toAirport,
            "toAirportCity": toAirport?.city ?? "",
            "toAirportCountry": toAirport?.country ?? "",
            "operatingCarrier": boardingPass.operatingCarrierDesignator,
            "airlineName": airline?.name ?? boardingPass.operatingCarrierDesignator,
            "airlineCountry": airline?.country ?? "",
            "flightNumber": boardingPass.flightNumber,
            "flightDateJulian": String(boardingPass.flightDateJulian),
            "flightDate": boardingPass.flightDate,
            "compartmentCode": boardingPass.compartmentCode,
            "seatNumber": boardingPass.seatNumber,
            "checkInSequenceNumber": boardingPass.checkInSequenceNumber,
            "passengerStatus": boardingPass.passengerStatus,
            "summary": boardingPass.summary
        ]
    }
    
    func isBoardingPassAlreadyPresent(_ str: String) -> Bool {
        guard !barcodeText(str).isEmpty,
              let sxDataModel = SxMagicVariables.shared.value(forKey: "dataModelMyCodes") as? SxDataModel else {
            return false
        }

        return sxDataModel.items.contains { item in
            item.item["text"] as? String == barcodeText(str)
        }
    }
}

//struct Action_decodeSelectedBoardingPass: SxActionProtocol {
//    let node: MagicNode?
//    
//    func execute(_ actionString: String) {
//        if let selectedCode = SxMagicVariables.shared.value(forKey: "selectedCode") {
//            print("JANA")
//        }
//    }
//}
