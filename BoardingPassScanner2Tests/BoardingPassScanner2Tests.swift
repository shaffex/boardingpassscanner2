//
//  BoardingPassScanner2Tests.swift
//  BoardingPassScanner2Tests
//
//  Created by Peter Popovec on 08/05/2026.
//

import MagicUiFramework
import Testing
@testable import BoardingPassScanner2

struct BoardingPassScanner2Tests {
    private struct ValidBoardingPassCase {
        let text: String
        let expectedItemFields: [String: String]
    }

    private let validBoardingPasses = [
        ValidBoardingPassCase(
            text: "M1STARR/MICHAEL       E9L3KEI ATHTLVLY 0546 131Y045C0109 100",
            expectedItemFields: [
                "name": "MICHAEL STARR",
                "type": "qr",
                "summary": "LY0546 ATH-TLV",
                "passengerSurname": "STARR",
                "passengerGivenName": "MICHAEL",
                "electronicTicketIndicator": "E",
                "pnr": "9L3KEI",
                "fromAirport": "ATH",
                "toAirport": "TLV",
                "operatingCarrier": "LY",
                "flightNumber": "0546",
                "flightDateJulian": "131",
                "compartmentCode": "Y",
                "seatNumber": "045C",
                "checkInSequenceNumber": "0109",
                "passengerStatus": "1"
            ]
        ),
        ValidBoardingPassCase(
            text: "M1HOSSOVA/DANA         UIQDKI LTNTATW9 5457 132Y035D0036 100",
            expectedItemFields: [
                "name": "DANA HOSSOVA",
                "type": "qr",
                "summary": "W95457 LTN-TAT",
                "passengerSurname": "HOSSOVA",
                "passengerGivenName": "DANA",
                "electronicTicketIndicator": "",
                "pnr": "UIQDKI",
                "fromAirport": "LTN",
                "toAirport": "TAT",
                "operatingCarrier": "W9",
                "flightNumber": "5457",
                "flightDateJulian": "132",
                "compartmentCode": "Y",
                "seatNumber": "035D",
                "checkInSequenceNumber": "0036",
                "passengerStatus": "1"
            ]
        )
    ]

    private let invalidBoardingPassTexts = [
        "not-a-boarding-pass"
    ]

    @Test func extractsBarcodeMetadataFromScannerAction() {
        let action = Action_addNewBoardingPass(node: nil)
        let boardingPass = validBoardingPasses[0]
        let actionString = scannerAction(for: boardingPass.text)

        #expect(action.barcodeType(actionString) == "qr")
        #expect(action.barcodeText(actionString) == boardingPass.text)
    }

    @Test func usesRawActionStringWhenNoScannerTextFieldExists() {
        let action = Action_addNewBoardingPass(node: nil)
        let boardingPass = validBoardingPasses[0]

        #expect(action.barcodeText(boardingPass.text) == boardingPass.text)
    }

    @Test @MainActor func executeAddsParsedBoardingPassToMyCodesDataModel() async {
        let action = Action_addNewBoardingPass(node: nil)

        
        
        for boardingPass in validBoardingPasses {
            print("Tesing boarding pass:", boardingPass.text)
            
            emptyMyCodesDataModel()

            action.execute(scannerAction(for: boardingPass.text))
            await MainActor.run {}

            guard let dataModel = myCodesDataModel() else {
                Issue.record("dataModel should not be nil")
                continue
            }

            #expect(dataModel.items.count == 1)

            guard let item = dataModel.items.first?.item else {
                Issue.record("dataModel should contain one item")
                continue
            }

            assertItem(item, matches: boardingPass)
        }
    }

    @Test @MainActor func executeDoesNotAppendInvalidBoardingPasses() async {
        let action = Action_addNewBoardingPass(node: nil)

        for boardingPassText in invalidBoardingPassTexts {
            let dataModel = emptyMyCodesDataModel()

            action.execute(scannerAction(for: boardingPassText))
            await MainActor.run {}

            #expect(dataModel.items.isEmpty)
        }
    }

    private func assertItem(_ item: [String: Any], matches boardingPass: ValidBoardingPassCase) {
        #expect(item["text"] as? String == boardingPass.text)
        #expect((item["scannedDate"] as? String)?.isEmpty == false)

        for (key, value) in boardingPass.expectedItemFields {
            #expect(item[key] as? String == value)
        }
    }

    private func scannerAction(for boardingPassText: String) -> String {
        "type:qr;text:\(boardingPassText)"
    }

    @discardableResult
    private func emptyMyCodesDataModel() -> SxDataModel {
        let dataModel = SxDataModel(name: "dataModelMyCodes", type: .json)
        dataModel.items = []
        SxMagicVariables.shared.setValue(dataModel, forKey: "dataModelMyCodes")
        return dataModel
    }

    private func myCodesDataModel() -> SxDataModel? {
        SxMagicVariables.shared.value(forKey: "dataModelMyCodes") as? SxDataModel
    }
}
