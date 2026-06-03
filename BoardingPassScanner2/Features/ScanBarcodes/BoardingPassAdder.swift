//
//  BoardingPassAdder.swift
//  BoardingPassScanner2
//
//  Shared logic for adding a scanned boarding pass to the store, so both the
//  single-scan action and batch scanning behave identically.
//

import Foundation

enum AddBoardingPassResult {
    case added(BoardingPassRecord)
    case duplicate
    case invalid
}

@MainActor
enum BoardingPassAdder {
    /// Adds a boarding pass to the store if it parses and isn't already saved.
    @discardableResult
    static func add(text: String, type: String) -> AddBoardingPassResult {
        let store = BoardingPassStore.shared

        if store.contains(text: text) {
            return .duplicate
        }

        guard (try? BoardingPass(parsing: text)) != nil else {
            return .invalid
        }

        guard let record = store.insertIfMissing(barcodeText: text, barcodeType: type) else {
            return .duplicate
        }

        return .added(record)
    }
}
