//
//  BoardingPassDecodedView.swift
//  BoardingPassScanner2
//
//  Created by OpenAI on 26/05/2026.
//

import SwiftUI

struct BoardingPassDecodedView: View {
    let record: BoardingPassRecord
    @State private var mapperRefreshToken = 0

    var body: some View {
        List {
            Section("Passenger") {
                field("Format Code (M)", record.formatCode)
                field("Number of Legs", String(max(record.numberOfLegs, decodedLegs.count)))
                field("Passenger Name", record.name)
                field("Surname", record.passengerSurname)
                field("Given Name", record.passengerGivenName)
                field("Electronic Ticket Indicator", record.electronicTicketIndicator)
            }

            ForEach(Array(decodedLegs.enumerated()), id: \.offset) { index, leg in
                Section("Leg \(index + 1)") {
                    legFields(leg)
                }
            }
        }
        .navigationTitle("Decoded fields")
        .onReceive(NotificationCenter.default.publisher(for: .boardingPassMapperDidReload)) { _ in
            mapperRefreshToken &+= 1
        }
    }

    private var decodedLegs: [BoardingPass.Leg] {
        record.decodedLegs
    }

    @ViewBuilder
    private func legFields(_ leg: BoardingPass.Leg) -> some View {
        let fromAirport = BoardingPassMapper.airport(for: leg.fromAirport)
        let toAirport = BoardingPassMapper.airport(for: leg.toAirport)
        let airline = BoardingPassMapper.airline(for: leg.operatingCarrierDesignator)
        let flightDate = ISO8601DateFormatter().date(from: leg.flightDate)

        field("Operating Carrier PNR", leg.operatingCarrierPNR)
        field("From Airport", leg.fromAirport)
        field("From Airport Name", fromAirport?.name ?? leg.fromAirport)
        field("From Airport City", fromAirport?.city ?? "")
        field("From Airport Country", fromAirport?.country ?? "")
        field("To Airport", leg.toAirport)
        field("To Airport Name", toAirport?.name ?? leg.toAirport)
        field("To Airport City", toAirport?.city ?? "")
        field("To Airport Country", toAirport?.country ?? "")
        field("Operating Carrier", leg.operatingCarrierDesignator)
        field("Airline Name", airline?.name ?? leg.operatingCarrierDesignator)
        field("Airline Country", airline?.country ?? "")
        field("Flight Number", leg.flightNumber)
        field("Flight Date (Julian)", String(leg.flightDateJulian))
        field("Flight Date", flightDate?.formatted(date: .abbreviated, time: .shortened) ?? leg.flightDate)
        field("Compartment Code", leg.compartmentCode)
        field("Seat Number", leg.seatNumber)
        field("Check-in Sequence Number", leg.checkInSequenceNumber)
        field("Passenger Status", leg.passengerStatus)
    }

    private func field(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value.isEmpty ? "--" : value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}
