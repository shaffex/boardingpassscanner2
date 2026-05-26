//
//  BoardingPassRecord.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import Foundation
import SwiftData

@Model
final class BoardingPassRecord {
    var text: String = ""

    var name: String = ""
    var type: String = ""
    var scannedDate: Date = Date.distantPast

    var formatCode: String = ""
    var numberOfLegs: Int = 0

    var passengerSurname: String = ""
    var passengerGivenName: String = ""
    var electronicTicketIndicator: String = ""
    var pnr: String = ""

    var fromAirport: String = ""
    var fromAirportName: String = ""
    var fromAirportCity: String = ""
    var fromAirportCountry: String = ""

    var toAirport: String = ""
    var toAirportName: String = ""
    var toAirportCity: String = ""
    var toAirportCountry: String = ""

    var operatingCarrier: String = ""
    var airlineName: String = ""
    var airlineCountry: String = ""

    var flightNumber: String = ""
    var flightDateJulian: Int = 0
    var flightDate: Date = Date.distantPast

    var compartmentCode: String = ""
    var seatNumber: String = ""
    var checkInSequenceNumber: String = ""
    var passengerStatus: String = ""

    var summary: String = ""

    init(
        text: String,
        name: String,
        type: String,
        scannedDate: Date = .now,
        formatCode: String = "",
        numberOfLegs: Int = 0,
        passengerSurname: String = "",
        passengerGivenName: String = "",
        electronicTicketIndicator: String = "",
        pnr: String = "",
        fromAirport: String = "",
        fromAirportName: String = "",
        fromAirportCity: String = "",
        fromAirportCountry: String = "",
        toAirport: String = "",
        toAirportName: String = "",
        toAirportCity: String = "",
        toAirportCountry: String = "",
        operatingCarrier: String = "",
        airlineName: String = "",
        airlineCountry: String = "",
        flightNumber: String = "",
        flightDateJulian: Int = 0,
        flightDate: Date = .distantPast,
        compartmentCode: String = "",
        seatNumber: String = "",
        checkInSequenceNumber: String = "",
        passengerStatus: String = "",
        summary: String = ""
    ) {
        self.text = text
        self.name = name
        self.type = type
        self.scannedDate = scannedDate
        self.formatCode = formatCode
        self.numberOfLegs = numberOfLegs
        self.passengerSurname = passengerSurname
        self.passengerGivenName = passengerGivenName
        self.electronicTicketIndicator = electronicTicketIndicator
        self.pnr = pnr
        self.fromAirport = fromAirport
        self.fromAirportName = fromAirportName
        self.fromAirportCity = fromAirportCity
        self.fromAirportCountry = fromAirportCountry
        self.toAirport = toAirport
        self.toAirportName = toAirportName
        self.toAirportCity = toAirportCity
        self.toAirportCountry = toAirportCountry
        self.operatingCarrier = operatingCarrier
        self.airlineName = airlineName
        self.airlineCountry = airlineCountry
        self.flightNumber = flightNumber
        self.flightDateJulian = flightDateJulian
        self.flightDate = flightDate
        self.compartmentCode = compartmentCode
        self.seatNumber = seatNumber
        self.checkInSequenceNumber = checkInSequenceNumber
        self.passengerStatus = passengerStatus
        self.summary = summary
    }
}

extension BoardingPassRecord {
    static func from(
        barcodeText: String,
        barcodeType: String,
        scannedDate: Date = .now,
        flightDateYear: Int? = nil
    ) -> BoardingPassRecord? {
        guard let boardingPass = try? BoardingPass(parsing: barcodeText, flightDateYear: flightDateYear) else {
            return BoardingPassRecord(
                text: barcodeText,
                name: "Unknown passenger",
                type: "Boarding pass",
                scannedDate: scannedDate
            )
        }

        let airline = BoardingPassMapper.airline(for: boardingPass.operatingCarrierDesignator)
        let fromAirport = BoardingPassMapper.airport(for: boardingPass.fromAirport)
        let toAirport = BoardingPassMapper.airport(for: boardingPass.toAirport)

        return BoardingPassRecord(
            text: barcodeText,
            name: boardingPass.passengerName.displayName,
            type: barcodeType,
            scannedDate: scannedDate,
            formatCode: boardingPass.formatCode,
            numberOfLegs: boardingPass.numberOfLegs,
            passengerSurname: boardingPass.passengerName.surname,
            passengerGivenName: boardingPass.passengerName.givenName,
            electronicTicketIndicator: boardingPass.electronicTicketIndicator,
            pnr: boardingPass.operatingCarrierPNR,
            fromAirport: boardingPass.fromAirport,
            fromAirportName: fromAirport?.name ?? boardingPass.fromAirport,
            fromAirportCity: fromAirport?.city ?? "",
            fromAirportCountry: fromAirport?.country ?? "",
            toAirport: boardingPass.toAirport,
            toAirportName: toAirport?.name ?? boardingPass.toAirport,
            toAirportCity: toAirport?.city ?? "",
            toAirportCountry: toAirport?.country ?? "",
            operatingCarrier: boardingPass.operatingCarrierDesignator,
            airlineName: airline?.name ?? boardingPass.operatingCarrierDesignator,
            airlineCountry: airline?.country ?? "",
            flightNumber: boardingPass.flightNumber,
            flightDateJulian: boardingPass.flightDateJulian,
            flightDate: ISO8601DateFormatter().date(from: boardingPass.flightDate) ?? .distantPast,
            compartmentCode: boardingPass.compartmentCode,
            seatNumber: boardingPass.seatNumber,
            checkInSequenceNumber: boardingPass.checkInSequenceNumber,
            passengerStatus: boardingPass.passengerStatus,
            summary: boardingPass.summary
        )
    }

    func applyMapperRefresh() {
        if let airline = BoardingPassMapper.airline(for: operatingCarrier) {
            airlineName = airline.name
            airlineCountry = airline.country
        }
        if let from = BoardingPassMapper.airport(for: fromAirport) {
            fromAirportName = from.name
            fromAirportCity = from.city
            fromAirportCountry = from.country
        }
        if let to = BoardingPassMapper.airport(for: toAirport) {
            toAirportName = to.name
            toAirportCity = to.city
            toAirportCountry = to.country
        }
    }
}
