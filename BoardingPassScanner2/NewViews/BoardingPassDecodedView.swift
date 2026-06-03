//
//  BoardingPassDecodedView.swift
//  BoardingPassScanner2
//
//  Created by OpenAI on 26/05/2026.
//

import SwiftUI
import UIKit

struct BoardingPassDecodedView: View {
    @Environment(BoardingPassMapper.self) private var mapper

    let record: BoardingPassRecord

    @State private var copiedField: String?

    var body: some View {
        List {
            summarySection
            rawDataSection
            passengerSection

            ForEach(Array(decodedLegs.enumerated()), id: \.offset) { index, leg in
                Section(legTitle(index: index, leg: leg)) {
                    legFields(leg)
                }
            }

            conditionalSections
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Decoded fields")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) { copiedToast }
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: copiedField)
    }

    // MARK: - Derived data

    private var decodedLegs: [BoardingPass.Leg] {
        record.decodedLegs
    }

    private var conditional: BoardingPassConditional? {
        record.conditional
    }

    private var symbologyName: String {
        switch record.type.lowercased() {
        case "pdf417": "PDF417"
        case "aztec": "Aztec"
        case "qr": "QR Code"
        case "code128": "Code 128"
        case "ean8": "EAN-8"
        case "ean13": "EAN-13"
        case "": "Boarding pass"
        default: record.type
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(record.fromAirport.isEmpty ? "—" : record.fromAirport)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Image(systemName: "airplane")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(record.toAirport.isEmpty ? "—" : record.toAirport)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Spacer(minLength: 0)
                }

                if !record.fromAirportCity.isEmpty || !record.toAirportCity.isEmpty {
                    Text("\(cityLabel(record.fromAirportCity, record.fromAirport)) → \(cityLabel(record.toAirportCity, record.toAirport))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                FlowLayout(spacing: 8) {
                    chip(record.airlineName.isEmpty ? record.operatingCarrier : record.airlineName,
                         systemImage: "building.2")
                    if !record.flightNumber.isEmpty {
                        chip("\(record.operatingCarrier) \(record.flightNumber)", systemImage: "number")
                    }
                    if !record.seatNumber.isEmpty {
                        chip("Seat \(record.seatNumber)", systemImage: "chair")
                    }
                }
                .font(.footnote)
            }
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)
        }
    }

    private func cityLabel(_ city: String, _ code: String) -> String {
        city.isEmpty ? code : city
    }

    private func chip(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.accentColor.opacity(0.12), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }

    // MARK: - Raw data

    private var rawDataSection: some View {
        Section("Raw data") {
            HStack(spacing: 10) {
                Image(systemName: record.isValidBoardingPass ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(record.isValidBoardingPass ? .green : .orange)
                Text(record.isValidBoardingPass ? "Valid IATA BCBP boarding pass" : "Not a recognized boarding pass")
                Spacer()
            }

            row("Symbology", symbologyName)
            row("Length", "\(record.text.count) chars")

            VStack(alignment: .leading, spacing: 8) {
                Text("Encoded string")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(record.text.isEmpty ? "—" : record.text)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    copy(record.text, label: "Encoded string")
                } label: {
                    Label("Copy raw string", systemImage: "doc.on.doc")
                        .font(.footnote.weight(.medium))
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Passenger

    private var passengerSection: some View {
        Section("Passenger") {
            row("Format code (M)", record.formatCode)
            row("Number of legs", String(max(record.numberOfLegs, decodedLegs.count)))
            row("Passenger name", record.name)
            row("Surname", record.passengerSurname)
            row("Given name", record.passengerGivenName)
            row("Electronic ticket", record.electronicTicketIndicator,
                meaning: electronicTicketMeaning(record.electronicTicketIndicator), mono: true)
        }
    }

    // MARK: - Legs

    private func legTitle(index: Int, leg: BoardingPass.Leg) -> String {
        let route = "\(leg.fromAirport)–\(leg.toAirport)"
        return "Leg \(index + 1) · \(route)"
    }

    @ViewBuilder
    private func legFields(_ leg: BoardingPass.Leg) -> some View {
        let fromAirport = mapper.airport(for: leg.fromAirport)
        let toAirport = mapper.airport(for: leg.toAirport)
        let airline = mapper.airline(for: leg.operatingCarrierDesignator)
        let flightDate = ISO8601DateFormatter().date(from: leg.flightDate)

        row("Booking reference (PNR)", leg.operatingCarrierPNR, mono: true)
        row("From", leg.fromAirport, meaning: airportSubtitle(fromAirport), mono: true)
        row("To", leg.toAirport, meaning: airportSubtitle(toAirport), mono: true)
        row("Operating carrier", leg.operatingCarrierDesignator,
            meaning: airline.map { [$0.name, $0.country].filter { !$0.isEmpty }.joined(separator: ", ") }, mono: true)
        row("Flight number", leg.flightNumber, mono: true)
        row("Flight date", flightDate?.formatted(date: .complete, time: .omitted) ?? leg.flightDate,
            meaning: "Julian day \(leg.flightDateJulian)")
        row("Cabin / compartment", leg.compartmentCode, mono: true)
        row("Seat number", leg.seatNumber, mono: true)
        row("Check-in sequence", leg.checkInSequenceNumber, mono: true)
        row("Passenger status", leg.passengerStatus,
            meaning: passengerStatusMeaning(leg.passengerStatus), mono: true)
    }

    private func airportSubtitle(_ airport: BoardingPassMapper.Airport?) -> String? {
        guard let airport else { return nil }
        return [airport.name, airport.city, airport.country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    // MARK: - Conditional

    @ViewBuilder
    private var conditionalSections: some View {
        if let conditional, conditional.hasAnyData {
            if conditional.isStandard {
                Section("Conditional · structure") {
                    row("Version number", conditional.versionNumber, mono: true)
                    row("Variable field size",
                        conditional.variableFieldSize > 0
                            ? "0x\(conditional.variableFieldSizeHex) (\(conditional.variableFieldSize))"
                            : "")
                }
            }

            if conditional.hasUniqueData {
                Section("Conditional · shared") {
                    row("Passenger description", conditional.passengerDescription,
                        meaning: passengerDescriptionMeaning(conditional.passengerDescription), mono: true)
                    row("Source of check-in", conditional.sourceOfCheckIn,
                        meaning: checkInSourceMeaning(conditional.sourceOfCheckIn), mono: true)
                    row("Source of issuance", conditional.sourceOfBoardingPassIssuance,
                        meaning: checkInSourceMeaning(conditional.sourceOfBoardingPassIssuance), mono: true)
                    row("Date of issue", conditional.dateOfIssue, meaning: "Year digit + Julian day", mono: true)
                    row("Document type", conditional.documentType,
                        meaning: documentTypeMeaning(conditional.documentType), mono: true)
                    row("Issuing airline", conditional.airlineDesignatorOfIssuer,
                        meaning: mapper.airline(for: conditional.airlineDesignatorOfIssuer)?.name, mono: true)
                    row("Baggage tag", conditional.baggageTagNumber, mono: true)
                    row("1st non-consecutive tag", conditional.firstNonConsecutiveBaggageTag, mono: true)
                    row("2nd non-consecutive tag", conditional.secondNonConsecutiveBaggageTag, mono: true)
                }
            }

            if conditional.hasRepeatedData {
                Section("Conditional · this leg") {
                    row("Airline numeric code", conditional.airlineNumericCode, mono: true)
                    row("Document / serial number", conditional.documentFormSerialNumber, mono: true)
                    row("Selectee indicator", conditional.selecteeIndicator,
                        meaning: selecteeMeaning(conditional.selecteeIndicator), mono: true)
                    row("Intl. doc verification", conditional.internationalDocumentVerification, mono: true)
                    row("Marketing carrier", conditional.marketingCarrierDesignator,
                        meaning: mapper.airline(for: conditional.marketingCarrierDesignator)?.name, mono: true)
                    row("Frequent flyer airline", conditional.frequentFlyerAirlineDesignator,
                        meaning: mapper.airline(for: conditional.frequentFlyerAirlineDesignator)?.name, mono: true)
                    row("Frequent flyer number", conditional.frequentFlyerNumber, mono: true)
                    row("ID/AD indicator", conditional.idAdIndicator, mono: true)
                    row("Free baggage allowance", conditional.freeBaggageAllowance, mono: true)
                    row("Fast track", conditional.fastTrack,
                        meaning: yesNoMeaning(conditional.fastTrack), mono: true)
                }
            }

            if !conditional.airlineUse.isEmpty {
                Section("Airline use") {
                    monoBlock(conditional.airlineUse)
                }
            }

            if !conditional.unknownData.isEmpty {
                Section("Unknown data") {
                    monoBlock(conditional.unknownData)
                }
            }
        }
    }

    private func monoBlock(_ value: String) -> some View {
        Text(value)
            .font(.system(.footnote, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contextMenu {
                Button { copy(value, label: "Value") } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
    }

    // MARK: - Field row

    private func row(_ label: String, _ value: String, meaning: String? = nil, mono: Bool = false) -> some View {
        let display = value.isEmpty ? "—" : value
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                if let meaning, !meaning.isEmpty, !value.isEmpty {
                    Text(meaning)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 12)
            Text(display)
                .font(mono ? .system(.body, design: .monospaced) : .body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .contentShape(Rectangle())
        .contextMenu {
            if !value.isEmpty {
                Button { copy(value, label: label) } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
        }
    }

    // MARK: - Copy feedback

    private func copy(_ value: String, label: String) {
        UIPasteboard.general.string = value
        Haptics.tap()
        copiedField = label
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if copiedField == label { copiedField = nil }
        }
    }

    @ViewBuilder
    private var copiedToast: some View {
        if let copiedField {
            Label("Copied \(copiedField)", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Coded value meanings

    private func electronicTicketMeaning(_ code: String) -> String? {
        code.uppercased() == "E" ? "Electronic ticket" : nil
    }

    private func passengerStatusMeaning(_ code: String) -> String? {
        switch code {
        case "0": "Ticket issued, not checked in"
        case "1": "Ticket issued, checked in"
        case "2": "Bags checked, not checked in"
        case "3": "Bags checked, checked in"
        case "4": "Passenger passed security"
        case "5": "Passenger boarded"
        default: nil
        }
    }

    private func checkInSourceMeaning(_ code: String) -> String? {
        switch code.uppercased() {
        case "W": "Web check-in"
        case "K": "Airport kiosk"
        case "R": "Remote / off-site"
        case "M": "Mobile device"
        case "O": "Airport agent"
        case "T": "Town agent"
        case "V": "Onboard"
        default: nil
        }
    }

    private func documentTypeMeaning(_ code: String) -> String? {
        switch code.uppercased() {
        case "B": "Boarding pass"
        case "I": "Itinerary receipt"
        default: nil
        }
    }

    private func selecteeMeaning(_ code: String) -> String? {
        switch code {
        case "0": "Not a selectee"
        case "1": "SSSS — secondary screening"
        case "3": "TSA PreCheck"
        default: nil
        }
    }

    private func passengerDescriptionMeaning(_ code: String) -> String? {
        switch code {
        case "0": "Adult"
        case "1": "Male"
        case "2": "Female"
        case "3": "Child"
        case "4": "Infant"
        case "5": "No passenger (cabin baggage)"
        case "6": "Adult travelling with infant"
        case "7": "Unaccompanied minor"
        default: nil
        }
    }

    private func yesNoMeaning(_ code: String) -> String? {
        switch code.uppercased() {
        case "Y": "Yes"
        case "N": "No"
        default: nil
        }
    }
}

/// A simple wrapping layout so chips flow onto multiple lines instead of truncating.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                maxRowWidth = max(maxRowWidth, x - spacing)
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        maxRowWidth = max(maxRowWidth, x - spacing)

        let width = maxWidth.isFinite ? maxWidth : maxRowWidth
        return CGSize(width: max(0, width), height: max(0, totalHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
