//
//  BoardingPassStore.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import Foundation
import SwiftData

@MainActor
final class BoardingPassStore {
    static let shared = BoardingPassStore()

    let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    private init() {
        do {
            let schema = Schema([BoardingPassRecord.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("[BoardingPassStore] Failed to create ModelContainer: \(error)")
            print("[BoardingPassStore] Underlying NSError: \(error as NSError)")
            fatalError("Failed to create BoardingPassRecord ModelContainer: \(error)")
        }
    }

    func allRecords() -> [BoardingPassRecord] {
        let descriptor = FetchDescriptor<BoardingPassRecord>()
        return (try? context.fetch(descriptor)) ?? []
    }

    func prefetchParsed() {
        for record in allRecords() {
            BoardingPassParseCache.shared.warm(
                text: record.text,
                flightDateYear: record.flightDateYear > 0 ? record.flightDateYear : nil
            )
        }
    }

    func record(forText text: String) -> BoardingPassRecord? {
        let descriptor = FetchDescriptor<BoardingPassRecord>(
            predicate: #Predicate { $0.text == text }
        )
        return try? context.fetch(descriptor).first
    }

    func contains(text: String) -> Bool {
        record(forText: text) != nil
    }

    @discardableResult
    func insertIfMissing(
        barcodeText: String,
        barcodeType: String,
        flightDateYear: Int? = nil
    ) -> BoardingPassRecord? {
        guard !contains(text: barcodeText),
              let record = BoardingPassRecord.from(
                barcodeText: barcodeText,
                barcodeType: barcodeType,
                flightDateYear: flightDateYear
              ) else {
            return nil
        }
        context.insert(record)
        save()
        BoardingPassParseCache.shared.warm(
            text: record.text,
            flightDateYear: record.flightDateYear > 0 ? record.flightDateYear : nil
        )
        return record
    }

    func delete(_ record: BoardingPassRecord) {
        let text = record.text
        context.delete(record)
        save()
        BoardingPassParseCache.shared.invalidate(text: text)
    }

    func deleteAll() {
        let texts = allRecords().map(\.text)
        for record in allRecords() {
            context.delete(record)
        }
        save()
        for text in texts {
            BoardingPassParseCache.shared.invalidate(text: text)
        }
    }

    func refreshMappings() {
        for record in allRecords() {
            record.applyMapperRefresh()
        }
        save()
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("[BoardingPassStore] Save failed: \(error)")
        }
    }
}
