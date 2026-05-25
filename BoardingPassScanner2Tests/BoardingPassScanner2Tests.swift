//
//  BoardingPassScanner2Tests.swift
//  BoardingPassScanner2Tests
//
//  Created by Peter Popovec on 08/05/2026.
//

import Foundation
import SwiftData
import Testing
@testable import BoardingPassScanner2

@MainActor
struct BoardingPassScanner2Tests {
    private struct ValidBoardingPassCase {
        let text: String
        let expectedFields: [String: String]
    }

    private let validBoardingPasses = [
        ValidBoardingPassCase(
            text: "M1STARR/MICHAEL       E9L3KEI ATHTLVLY 0546 131Y045C0109 100",
            expectedFields: [
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
                "compartmentCode": "Y",
                "seatNumber": "045C",
                "checkInSequenceNumber": "0109",
                "passengerStatus": "1",
                "formatCode": "M"
            ]
        ),
        ValidBoardingPassCase(
            text: "M1HOSSOVA/DANA         UIQDKI LTNTATW9 5457 132Y035D0036 100",
            expectedFields: [
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
                "compartmentCode": "Y",
                "seatNumber": "035D",
                "checkInSequenceNumber": "0036",
                "passengerStatus": "1",
                "formatCode": "M"
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

    @Test func recordFromValidBoardingPassPopulatesExpectedFields() {
        for boardingPass in validBoardingPasses {
            guard let record = BoardingPassRecord.from(
                barcodeText: boardingPass.text,
                barcodeType: "qr"
            ) else {
                Issue.record("Record should not be nil for \(boardingPass.text)")
                continue
            }

            #expect(record.text == boardingPass.text)
            assertRecord(record, matches: boardingPass.expectedFields)
        }
    }

    @Test func recordFromInvalidBoardingPassFallsBackToUnknown() {
        for text in invalidBoardingPassTexts {
            let record = BoardingPassRecord.from(barcodeText: text, barcodeType: "qr")
            #expect(record?.name == "Unknown passenger")
            #expect(record?.text == text)
        }
    }

    private func assertRecord(_ record: BoardingPassRecord, matches expected: [String: String]) {
        for (key, value) in expected {
            let actual: String
            switch key {
            case "name": actual = record.name
            case "type": actual = record.type
            case "summary": actual = record.summary
            case "passengerSurname": actual = record.passengerSurname
            case "passengerGivenName": actual = record.passengerGivenName
            case "electronicTicketIndicator": actual = record.electronicTicketIndicator
            case "pnr": actual = record.pnr
            case "fromAirport": actual = record.fromAirport
            case "toAirport": actual = record.toAirport
            case "operatingCarrier": actual = record.operatingCarrier
            case "flightNumber": actual = record.flightNumber
            case "compartmentCode": actual = record.compartmentCode
            case "seatNumber": actual = record.seatNumber
            case "checkInSequenceNumber": actual = record.checkInSequenceNumber
            case "passengerStatus": actual = record.passengerStatus
            case "formatCode": actual = record.formatCode
            default:
                Issue.record("Unknown field key: \(key)")
                continue
            }
            #expect(actual == value, "expected \(key) to be \(value) but was \(actual)")
        }
    }

    private func scannerAction(for boardingPassText: String) -> String {
        "type:qr;text:\(boardingPassText)"
    }
}
