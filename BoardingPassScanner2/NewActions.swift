//
//  NewActions.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 15/05/2025.
//

import Foundation
import MagicUiFramework


struct Action_addNewBoardingBass: SxActionProtocol {
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
        guard (try? BoardingPass(parsing: text)) != nil else {
            PluginActions.shared.runAction("presentAlert:myAlertInvalidCode")
            return
        }
        
        if let sxDataModel = SxMagicVariables.shared.value(forKey: "dataModelMyCodes") as? SxDataModel {
            let item = SxDataModelItem(item: itemData(for: text, barcodeType: barcodeType(actionString)))
            sxDataModel.items.append(item)

        }
        
    }

    private func itemData(for barcodeText: String, barcodeType: String) -> [String: String] {
        let scannedDate = ISO8601DateFormatter().string(from: Date())

        guard let boardingPass = try? BoardingPass(parsing: barcodeText) else {
            return [
                "name": "Unknown passenger",
                "text": barcodeText,
                "type": "Boarding pass",
                "scannedDate": scannedDate
            ]
        }

        return [
            "name": boardingPass.passengerName.displayName,
            "text": barcodeText,
            "type": barcodeType,
            "scannedDate": scannedDate,
            "passengerSurname": boardingPass.passengerName.surname,
            "passengerGivenName": boardingPass.passengerName.givenName,
            "electronicTicketIndicator": boardingPass.electronicTicketIndicator,
            "pnr": boardingPass.operatingCarrierPNR,
            "fromAirport": boardingPass.fromAirport,
            "toAirport": boardingPass.toAirport,
            "operatingCarrier": boardingPass.operatingCarrierDesignator,
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
}
