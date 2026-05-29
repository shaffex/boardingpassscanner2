//
//  BoardingPassCard.swift
//  BoardingPassScanner2
//
//  Created by OpenAI on 26/05/2026.
//

import SwiftUI

struct BoardingPassCard: View {
    enum Style {
        case regular
        case compact
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(BoardingPassMapper.self) private var mapper

    let record: BoardingPassRecord
    var style: Style = .regular

    var body: some View {
        VStack(spacing: verticalSpacing) {
            header
            route

            if isMultiLeg {
                multiLegRoute
            }

            Divider()
                .overlay(dividerColor)

            details
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.cyan)
                .frame(width: 4)
                .padding(.vertical, sideStripePadding)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        }
        .shadow(color: shadowColor, radius: 18, x: 0, y: 10)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: style == .compact ? 10 : 12) {
            HStack(alignment: .center, spacing: 12) {
                Text(flightCode)
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color.cyan)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(Color.cyan.opacity(0.18), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(airlineDisplayName)
                    .font(airlineFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                if isMultiLeg {
                    Text("\(parsedLegs.count) LEGS")
                        .font(.system(style == .compact ? .caption2 : .caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(Color.cyan)
                        .padding(.horizontal, style == .compact ? 8 : 10)
                        .frame(height: style == .compact ? 24 : 28)
                        .background(Color.cyan.opacity(0.14), in: Capsule())
                }
            }

            Text(relativeDateText)
                .font(.system(style == .compact ? .caption : .subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var route: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                airportCode(record.fromAirport)

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    Rectangle()
                        .fill(.secondary.opacity(0.55))
                        .frame(width: style == .compact ? 18 : 22, height: 1)
                    Image(systemName: "airplane")
                        .font(.system(size: style == .compact ? 28 : 32, weight: .regular))
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(.secondary.opacity(0.55))
                        .frame(width: style == .compact ? 18 : 22, height: 1)
                }

                Spacer(minLength: 8)

                airportCode(destinationAirportCode)
            }

            HStack(spacing: 8) {
                cityText(fromAirportCity, alignment: .leading)
                Spacer(minLength: 8)
                cityText(destinationAirportCity, alignment: .trailing)
            }
        }
    }

    private func airportCode(_ code: String) -> some View {
        Text(displayValue(code))
            .font(.system(size: airportCodeSize, weight: .bold, design: .default))
            .foregroundStyle(primaryText)
            .minimumScaleFactor(0.75)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func cityText(_ city: String, alignment: HorizontalAlignment) -> some View {
        Text(displayValue(city))
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(alignment: alignment == .leading ? .leading : .trailing)
    }

    private var details: some View {
        HStack(alignment: .top) {
            detailBlock(title: "PASSENGER", value: record.name)
            Spacer()
            detailBlock(title: "SEAT", value: displayValue(formattedSeatNumber(record.seatNumber)))
            Spacer()
            detailBlock(title: "DATE", value: dateText)
                .frame(alignment: .trailing)
        }
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.08)
    }

    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.13) : Color.black.opacity(0.1)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var verticalSpacing: CGFloat {
        style == .compact ? 16 : 18
    }

    private var cardPadding: CGFloat {
        style == .compact ? 18 : 22
    }

    private var cornerRadius: CGFloat {
        style == .compact ? 22 : 26
    }

    private var sideStripePadding: CGFloat {
        style == .compact ? 16 : 18
    }

    private var airlineFont: Font {
        style == .compact ? .headline.weight(.semibold) : .title3.weight(.medium)
    }

    private var airportCodeSize: CGFloat {
        style == .compact ? 34 : 38
    }

    private var flightCode: String {
        [record.operatingCarrier, record.flightNumber]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private var airlineDisplayName: String {
        mapper.airlineName(for: record.operatingCarrier)
    }

    private var fromAirportCity: String {
        mapper.airport(for: record.fromAirport)?.city ?? ""
    }

    private var parsedLegs: [BoardingPass.Leg] {
        record.decodedLegs
    }

    private var isMultiLeg: Bool {
        parsedLegs.count > 1
    }

    private var destinationAirportCode: String {
        parsedLegs.last?.toAirport ?? record.toAirport
    }

    private var destinationAirportCity: String {
        guard let lastDestination = parsedLegs.last?.toAirport else {
            return mapper.airport(for: record.toAirport)?.city ?? ""
        }

        return mapper.airport(for: lastDestination)?.city ?? ""
    }

    private var routeCodes: [String] {
        guard let firstLeg = parsedLegs.first else {
            return [record.fromAirport, record.toAirport].filter { !$0.isEmpty }
        }

        return [firstLeg.fromAirport] + parsedLegs.map(\.toAirport)
    }

    private var relativeDateText: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let flightDay = calendar.startOfDay(for: record.flightDate)
        let days = calendar.dateComponents([.day], from: today, to: flightDay).day ?? 0

        if days == 0 {
            return "TODAY"
        }

        let absoluteDays = abs(days)
        if absoluteDays >= 365 {
            let years = max(1, absoluteDays / 365)
            let unit = years == 1 ? "YEAR" : "YEARS"
            return days > 0 ? "IN \(years) \(unit)" : "\(years) \(unit) AGO"
        }

        return days > 0 ? "IN \(days) DAYS" : "\(absoluteDays) DAYS AGO"
    }

    private var dateText: String {
        record.flightDate.formatted(.dateTime.day().month(.abbreviated))
    }

    private var multiLegRoute: some View {
        HStack(spacing: 7) {
            ForEach(Array(routeCodes.enumerated()), id: \.offset) { index, code in
                Text(displayValue(code))
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(index == 0 || index == routeCodes.count - 1 ? primaryText : Color.cyan)

                if index < routeCodes.count - 1 {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Color.cyan.opacity(colorScheme == .dark ? 0.1 : 0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func detailBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: style == .compact ? 5 : 6) {
            Text(title)
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(2)
            Text(displayValue(value))
                .font(.headline.weight(.semibold))
                .foregroundStyle(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private func displayValue(_ value: String) -> String {
        value.isEmpty ? "--" : value
    }

    private func formattedSeatNumber(_ seat: String) -> String {
        let trimmed = seat.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return trimmed }
        let digits = trimmed.prefix(while: \.isNumber)
        guard !digits.isEmpty, let number = Int(digits) else { return trimmed }
        return "\(number)\(trimmed.dropFirst(digits.count))"
    }
}

