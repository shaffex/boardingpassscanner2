//
//  BoardingPassCard+Previews.swift
//  BoardingPassScanner2
//

#if DEBUG

import SwiftUI

private enum CardPreviewFactory {
    struct AdditionalLeg {
        let from: String
        let to: String
        let carrier: String
        let flight: String
        let seat: String
    }

    static func record(
        name: String,
        from: String,
        to: String,
        carrier: String,
        flight: String,
        seat: String = "012A",
        dayOffsetFromToday: Int = 0,
        additionalLegs: [AdditionalLeg] = []
    ) -> BoardingPassRecord {
        let calendar = Calendar(identifier: .gregorian)
        let targetDate = calendar.date(byAdding: .day, value: dayOffsetFromToday, to: Date()) ?? Date()
        let julian = calendar.ordinality(of: .day, in: .year, for: targetDate) ?? 1
        let year = calendar.component(.year, from: targetDate)
        let julianText = String(format: "%03d", julian)

        let totalLegs = 1 + additionalLegs.count

        var text = "M\(totalLegs)"
            + padRight(name, 20)
            + "E"
            + padRight("ABC1234", 7)
            + padRight(from, 3)
            + padRight(to, 3)
            + padRight(carrier, 3)
            + padLeft(flight, 5)
            + julianText
            + "Y"
            + padRight(seat, 4)
            + "00100"
            + "0"
            + "00"

        for leg in additionalLegs {
            text += padRight("DEF5678", 7)
                + padRight(leg.from, 3)
                + padRight(leg.to, 3)
                + padRight(leg.carrier, 3)
                + padLeft(leg.flight, 5)
                + julianText
                + "Y"
                + padRight(leg.seat, 4)
                + "00200"
                + "0"
        }

        return BoardingPassRecord(text: text, type: "PDF417", flightDateYear: year)
    }

    static func makeMapper() -> BoardingPassMapper {
        let mapper = BoardingPassMapper.shared
        mapper.installForTesting(
            airlines: [
                .init(code: "BA", name: "British Airways", country: "United Kingdom"),
                .init(code: "AA", name: "American Airlines", country: "United States"),
                .init(code: "LH", name: "Lufthansa", country: "Germany"),
                .init(code: "EK", name: "Emirates The Airline Of The United Arab Emirates", country: "UAE"),
                .init(code: "FR", name: "Ryanair", country: "Ireland"),
                .init(code: "OK", name: "Czech Airlines", country: "Czechia"),
                .init(code: "U2", name: "easyJet", country: "United Kingdom"),
            ],
            airports: [
                .init(code: "LHR", name: "Heathrow", city: "London", country: "UK"),
                .init(code: "LTN", name: "Luton", city: "London Lomger Text Very Long", country: "UK"),
                .init(code: "TAT", name: "Tatry", city: "Poprad Longer Text", country: "Slovakia"),
                .init(code: "JFK", name: "John F. Kennedy", city: "New York", country: "USA"),
                .init(code: "LAX", name: "Los Angeles International", city: "Los Angeles", country: "USA"),
                .init(code: "CDG", name: "Charles de Gaulle", city: "Paris", country: "France"),
                .init(code: "NRT", name: "Narita International", city: "Tokyo", country: "Japan"),
                .init(code: "AMS", name: "Schiphol", city: "Amsterdam Schiphol", country: "Netherlands"),
                .init(code: "GRU", name: "Guarulhos", city: "São Paulo Guarulhos Aeroporto", country: "Brazil"),
                .init(code: "FRA", name: "Frankfurt Main", city: "Frankfurt am Main", country: "Germany"),
                .init(code: "PRG", name: "Václav Havel", city: "Prague", country: "Czechia"),
            ]
        )
        return mapper
    }

    private static func padRight(_ value: String, _ length: Int) -> String {
        let truncated = String(value.prefix(length))
        return truncated.padding(toLength: length, withPad: " ", startingAt: 0)
    }

    private static func padLeft(_ value: String, _ length: Int) -> String {
        let truncated = String(value.prefix(length))
        return String(repeating: " ", count: max(0, length - truncated.count)) + truncated
    }
}

private struct CardPreviewVariant: Identifiable {
    let id = UUID()
    let label: String
    let record: BoardingPassRecord
}

private struct BoardingPassCardPreviewGallery: View {
    let style: BoardingPassCard.Style

    private let mapper = CardPreviewFactory.makeMapper()

    private let variants: [CardPreviewVariant] = [
        .init(label: "Realistic (matches screenshot)",
              record: CardPreviewFactory.record(
                name: "HOSSOVA/LIVE",
                from: "TAT", to: "LTN",
                carrier: "BA", flight: "705",
                seat: "035D")),

        .init(label: "Short everything",
              record: CardPreviewFactory.record(
                name: "LI/AL",
                from: "LHR", to: "JFK",
                carrier: "BA", flight: "1")),

        .init(label: "Long passenger name",
              record: CardPreviewFactory.record(
                name: "VANDERMEEREN/CHRISTOPHER",
                from: "LHR", to: "JFK",
                carrier: "BA", flight: "175")),

        .init(label: "Long city names (GRU → AMS)",
              record: CardPreviewFactory.record(
                name: "POPOVEC/PETER",
                from: "GRU", to: "AMS",
                carrier: "LH", flight: "5060",
                seat: "022K")),

        .init(label: "Long airline name + long flight no.",
              record: CardPreviewFactory.record(
                name: "DOE/JOHN",
                from: "LHR", to: "JFK",
                carrier: "EK", flight: "12345",
                seat: "001A")),

        .init(label: "Unknown airports + unknown airline",
              record: CardPreviewFactory.record(
                name: "TEST/USER",
                from: "ZZZ", to: "QQQ",
                carrier: "XX", flight: "9999",
                seat: "099Z")),

        .init(label: "Multi-leg (2 legs)",
              record: CardPreviewFactory.record(
                name: "POPOVEC/PETER",
                from: "PRG", to: "LHR",
                carrier: "OK", flight: "566",
                seat: "012A",
                additionalLegs: [
                    .init(from: "LHR", to: "JFK", carrier: "BA", flight: "175", seat: "014C")
                ])),

        .init(label: "Multi-leg (3 legs, long cities)",
              record: CardPreviewFactory.record(
                name: "SMITH/JANE",
                from: "GRU", to: "AMS",
                carrier: "LH", flight: "5061",
                seat: "032A",
                additionalLegs: [
                    .init(from: "AMS", to: "FRA", carrier: "LH", flight: "991", seat: "021A"),
                    .init(from: "FRA", to: "NRT", carrier: "LH", flight: "710", seat: "040K"),
                ])),

        .init(label: "Future date (IN 14 DAYS)",
              record: CardPreviewFactory.record(
                name: "DOE/JOHN",
                from: "LHR", to: "CDG",
                carrier: "BA", flight: "302",
                seat: "021A",
                dayOffsetFromToday: 14)),

        .init(label: "Past date (45 DAYS AGO)",
              record: CardPreviewFactory.record(
                name: "DOE/JOHN",
                from: "LHR", to: "CDG",
                carrier: "BA", flight: "302",
                seat: "021A",
                dayOffsetFromToday: -45)),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ForEach(variants) { variant in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(variant.label.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        BoardingPassCard(record: variant.record, style: style)
                    }
                }
            }
            .padding(18)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .environment(mapper)
    }
}

#Preview("Regular card (Dark)") {
    BoardingPassCardPreviewGallery(style: .regular)
        .preferredColorScheme(.dark)
}

#Preview("Regular card (Light)") {
    BoardingPassCardPreviewGallery(style: .regular)
        .preferredColorScheme(.light)
}

#Preview("Compact card (Dark)") {
    BoardingPassCardPreviewGallery(style: .compact)
        .preferredColorScheme(.dark)
}

#Preview("Compact card (Light)") {
    BoardingPassCardPreviewGallery(style: .compact)
        .preferredColorScheme(.light)
}

#endif
