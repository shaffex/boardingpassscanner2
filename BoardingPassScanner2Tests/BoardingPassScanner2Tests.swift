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

    private let multiLegBoardingPassText = "M2VLASIUK/DIANA       E8ABI6J WAWAUHEY 0160 142Y040H0030 349>5180 O6142BEY 06071152910012A60792366202810                           NN8ABI6J AUHMLEEY 0376 143Y021G0002 32D2A60792366202810                           NN"

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

    @Test func parsesMultiLegBoardingPass() throws {
        let boardingPass = try BoardingPass(parsing: multiLegBoardingPassText, flightDateYear: 2026)

        #expect(boardingPass.numberOfLegs == 2)
        #expect(boardingPass.legs.count == 2)
        #expect(boardingPass.summary == "EY0160 WAW-AUH")
        #expect(boardingPass.passengerName.displayName == "DIANA VLASIUK")

        #expect(boardingPass.legs[0].flightCode == "EY0160")
        #expect(boardingPass.legs[0].route == "WAW-AUH")
        #expect(boardingPass.legs[0].flightDateJulian == 142)
        #expect(boardingPass.legs[0].seatNumber == "040H")
        #expect(boardingPass.legs[0].checkInSequenceNumber == "0030")
        #expect(boardingPass.legs[0].passengerStatus == "3")

        #expect(boardingPass.legs[1].flightCode == "EY0376")
        #expect(boardingPass.legs[1].route == "AUH-MLE")
        #expect(boardingPass.legs[1].flightDateJulian == 143)
        #expect(boardingPass.legs[1].seatNumber == "021G")
        #expect(boardingPass.legs[1].checkInSequenceNumber == "0002")
        #expect(boardingPass.legs[1].passengerStatus == "3")
    }

    @Test func recordFromMultiLegBoardingPassUsesFirstLegForDisplay() throws {
        let record = try #require(BoardingPassRecord.from(
            barcodeText: multiLegBoardingPassText,
            barcodeType: "pdf417",
            flightDateYear: 2026
        ))

        #expect(record.numberOfLegs == 2)
        #expect(record.name == "DIANA VLASIUK")
        #expect(record.type == "pdf417")
        #expect(record.summary == "EY0160 WAW-AUH")
        #expect(record.fromAirport == "WAW")
        #expect(record.toAirport == "AUH")
        #expect(record.operatingCarrier == "EY")
        #expect(record.flightNumber == "0160")
        #expect(record.flightDateJulian == 142)
        #expect(record.seatNumber == "040H")
        #expect(record.checkInSequenceNumber == "0030")
        #expect(record.passengerStatus == "3")
    }

    @Test func recordUsesImportedYearForJulianFlightDate() throws {
        let record = try #require(BoardingPassRecord.from(
            barcodeText: validBoardingPasses[0].text,
            barcodeType: "qr",
            flightDateYear: 2024
        ))

        #expect(record.flightDate == ISO8601DateFormatter().date(from: "2024-05-10T13:30:00Z"))
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
