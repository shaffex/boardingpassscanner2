//
//  BoardingPassConditional.swift
//  BoardingPassScanner2
//
//  Best-effort decoder for the optional / conditional items of an IATA BCBP
//  barcode (Resolution 792). The core `BoardingPass` parser only reads the
//  mandatory fields; this adds the shared ("unique") and first-leg ("repeated")
//  conditional fields plus any airline-use / unknown trailing data, so the
//  decoded screen can show the full structure.
//
//  Parsing never throws: anything missing or truncated simply stays empty.
//

import Foundation

struct BoardingPassConditional: Equatable {
    /// True when a standard `>` versioned conditional block was found.
    var isStandard = false

    var versionNumber = ""

    /// Field size of the variable (conditional) portion of leg 1, as it appears
    /// in the barcode (2 hex digits) and its decimal value.
    var variableFieldSizeHex = ""
    var variableFieldSize = 0

    // Shared ("unique") conditional fields — present once for the whole pass.
    var passengerDescription = ""
    var sourceOfCheckIn = ""
    var sourceOfBoardingPassIssuance = ""
    var dateOfIssue = ""
    var documentType = ""
    var airlineDesignatorOfIssuer = ""
    var baggageTagNumber = ""
    var firstNonConsecutiveBaggageTag = ""
    var secondNonConsecutiveBaggageTag = ""

    // Repeated conditional fields — shown here for the first leg.
    var airlineNumericCode = ""
    var documentFormSerialNumber = ""
    var selecteeIndicator = ""
    var internationalDocumentVerification = ""
    var marketingCarrierDesignator = ""
    var frequentFlyerAirlineDesignator = ""
    var frequentFlyerNumber = ""
    var idAdIndicator = ""
    var freeBaggageAllowance = ""
    var fastTrack = ""

    /// Free-form data reserved for individual airline use.
    var airlineUse = ""

    /// Any conditional data that didn't follow the standard `>` structure.
    var unknownData = ""

    var hasUniqueData: Bool {
        ![passengerDescription, sourceOfCheckIn, sourceOfBoardingPassIssuance,
          dateOfIssue, documentType, airlineDesignatorOfIssuer, baggageTagNumber,
          firstNonConsecutiveBaggageTag, secondNonConsecutiveBaggageTag]
            .allSatisfy { $0.isEmpty }
    }

    var hasRepeatedData: Bool {
        ![airlineNumericCode, documentFormSerialNumber, selecteeIndicator,
          internationalDocumentVerification, marketingCarrierDesignator,
          frequentFlyerAirlineDesignator, frequentFlyerNumber, idAdIndicator,
          freeBaggageAllowance, fastTrack]
            .allSatisfy { $0.isEmpty }
    }

    var hasAnyData: Bool {
        isStandard || hasUniqueData || hasRepeatedData
            || !airlineUse.isEmpty || !unknownData.isEmpty
    }
}

extension BoardingPassConditional {
    /// Parses the conditional section of a BCBP string. Returns `nil` only when
    /// there is no conditional region at all.
    init?(parsing rawValue: String) {
        var cursor = Cursor(rawValue)

        guard cursor.remaining >= 60 else { return nil }
        guard cursor.read(1) == "M" else { return nil }
        guard let legs = Int(cursor.read(1).trimmedField), legs >= 1 else { return nil }

        // Skip the 35 mandatory repeated fields of leg 1.
        cursor.skip(35)

        // Size of the variable (conditional) field for leg 1.
        let sizeHex = cursor.readRaw(2)
        let size = Int(sizeHex.trimmingCharacters(in: .whitespaces), radix: 16) ?? 0
        guard size > 0, cursor.remaining > 0 else { return nil }

        self.variableFieldSizeHex = sizeHex
        self.variableFieldSize = size

        let region = cursor.read(size)
        var conditional = Cursor(region)

        guard conditional.read(1) == ">" else {
            // Non-standard conditional payload — surface it verbatim.
            self.unknownData = region.trimmedField
            return
        }

        self.isStandard = true
        self.versionNumber = conditional.read(1).trimmedField

        // Shared / unique structured message.
        let uniqueSize = conditional.readHexSize(2)
        var unique = Cursor(conditional.read(uniqueSize))
        self.passengerDescription = unique.read(1).trimmedField
        self.sourceOfCheckIn = unique.read(1).trimmedField
        self.sourceOfBoardingPassIssuance = unique.read(1).trimmedField
        self.dateOfIssue = unique.read(4).trimmedField
        self.documentType = unique.read(1).trimmedField
        self.airlineDesignatorOfIssuer = unique.read(3).trimmedField
        self.baggageTagNumber = unique.read(13).trimmedField
        self.firstNonConsecutiveBaggageTag = unique.read(13).trimmedField
        self.secondNonConsecutiveBaggageTag = unique.read(13).trimmedField

        // Repeated structured message (first leg).
        let repeatedSize = conditional.readHexSize(2)
        var repeated = Cursor(conditional.read(repeatedSize))
        self.airlineNumericCode = repeated.read(3).trimmedField
        self.documentFormSerialNumber = repeated.read(10).trimmedField
        self.selecteeIndicator = repeated.read(1).trimmedField
        self.internationalDocumentVerification = repeated.read(1).trimmedField
        self.marketingCarrierDesignator = repeated.read(3).trimmedField
        self.frequentFlyerAirlineDesignator = repeated.read(3).trimmedField
        self.frequentFlyerNumber = repeated.read(16).trimmedField
        self.idAdIndicator = repeated.read(1).trimmedField
        self.freeBaggageAllowance = repeated.read(3).trimmedField
        self.fastTrack = repeated.read(1).trimmedField

        // Whatever remains in the conditional region is for airline use.
        self.airlineUse = conditional.readRemaining().trimmedField
    }
}

// MARK: - Lightweight forward scanner

private struct Cursor {
    private let chars: [Character]
    private var index = 0

    init(_ value: String) {
        chars = Array(value)
    }

    var remaining: Int { max(0, chars.count - index) }

    mutating func skip(_ count: Int) {
        index = min(chars.count, index + max(0, count))
    }

    /// Reads up to `count` characters (clamped to what's left).
    mutating func readRaw(_ count: Int) -> String {
        let take = max(0, min(count, remaining))
        let slice = String(chars[index..<(index + take)])
        index += take
        return slice
    }

    mutating func read(_ count: Int) -> String { readRaw(count) }

    mutating func readRemaining() -> String { readRaw(remaining) }

    /// Reads `count` characters and interprets them as a hex byte count.
    mutating func readHexSize(_ count: Int) -> Int {
        Int(readRaw(count).trimmingCharacters(in: .whitespaces), radix: 16) ?? 0
    }
}

private extension String {
    var trimmedField: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
