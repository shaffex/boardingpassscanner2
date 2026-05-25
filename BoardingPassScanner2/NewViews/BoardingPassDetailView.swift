//
//  BoardingPassDetailView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import SwiftUI
import PassKit
import MagicUiFramework

struct BoardingPassDetailView: View {
    let record: BoardingPassRecord

    @Environment(\.dismiss) private var dismiss

    @State private var showDecodedSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            Section("Pass") {
                Text(record.text)
                    .font(.caption.monospaced())
                Text("Code Type: \(record.type)")
                Text("Seat Number: \(record.seatNumber)")
                Text("flightDate: \(record.flightDate.formatted(date: .abbreviated, time: .shortened))")
            }

            Section {
                MagicUiView(string: "<body><barcode barcodeType=\"\(record.type)\">\(record.text)</barcode></body>")
                    .frame(maxWidth: .infinity, minHeight: 120)
            }

            Section {
                AddToWalletButton(addPassButtonStyle: .black) {
                    Action_addPass.presentForRecord(record)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .navigationTitle("Letenka")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showDecodedSheet = true
                    } label: {
                        Label("Decode fields", systemImage: "tray.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Warning", isPresented: $showDeleteAlert) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) {
                BoardingPassStore.shared.delete(record)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this boarding pass?\n\nPlease note, this action is irreversible.")
        }
        .sheet(isPresented: $showDecodedSheet) {
            NavigationStack {
                BoardingPassDecodedView(record: record)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showDecodedSheet = false }
                        }
                    }
            }
        }
    }
}

struct BoardingPassDecodedView: View {
    let record: BoardingPassRecord

    var body: some View {
        List {
            field("Format Code (M)", record.formatCode)
            field("Number of Legs", String(record.numberOfLegs))
            field("Passenger Name", record.name)
            field("Surname", record.passengerSurname)
            field("Given Name", record.passengerGivenName)
            field("Electronic Ticket Indicator", record.electronicTicketIndicator)
            field("Operating Carrier PNR", record.pnr)
            field("From Airport", record.fromAirport)
            field("From Airport Name", record.fromAirportName)
            field("From Airport City", record.fromAirportCity)
            field("From Airport Country", record.fromAirportCountry)
            field("To Airport", record.toAirport)
            field("To Airport Name", record.toAirportName)
            field("To Airport City", record.toAirportCity)
            field("To Airport Country", record.toAirportCountry)
            field("Operating Carrier", record.operatingCarrier)
            field("Airline Name", record.airlineName)
            field("Airline Country", record.airlineCountry)
            field("Flight Number", record.flightNumber)
            field("Flight Date (Julian)", String(record.flightDateJulian))
            field("Flight Date", record.flightDate.formatted(date: .abbreviated, time: .shortened))
            field("Compartment Code", record.compartmentCode)
            field("Seat Number", record.seatNumber)
            field("Check-in Sequence Number", record.checkInSequenceNumber)
            field("Passenger Status", record.passengerStatus)
        }
        .navigationTitle("Decoded fields")
    }

    private func field(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}


