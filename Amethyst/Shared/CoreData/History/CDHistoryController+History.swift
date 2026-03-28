//
//  CDHistoryController+History.swift
//  Amethyst Browser
//
//  Created by Codex on 28.03.26.
//

import CoreData
import Foundation

extension CDHistoryController {
    func fetchAllHistoryDays() -> [HistoryDay] {
        let request = HistoryDay.createFetchRequest()
        request.includesSubentities = false
        request.relationshipKeyPathsForPrefetching = ["historyItems"]
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \HistoryDay.dayTime, ascending: false)
        ]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            Self.logger.error("Error while fetching all prefetched HistoryDays: \(error.localizedDescription)")
        }
        return []
    }

    func deleteAllVisits(matchingCanonicalURL canonicalURL: String) -> [String] {
        let items = fetchAllHistoryItems().filter {
            guard let url = $0.url else { return false }
            return HistoryCanonicalizer.canonicalURLString(for: url) == canonicalURL
        }
        let affectedURLStrings = Array(Set(items.compactMap { $0.url?.absoluteString })).sorted()

        guard !items.isEmpty else { return [] }

        items.forEach { container.viewContext.delete($0) }
        save()
        pruneEmptyDays()
        return affectedURLStrings
    }

    func clearEntity() {
        fetchAllHistoryDays().forEach {
            container.viewContext.delete($0)
        }
        save()
    }

    func fetchSearchIndexSnapshots(for urlStrings: [String]) async -> [HistorySearchIndexSnapshot] {
        let uniqueURLStrings = Array(Set(urlStrings.filter({ !$0.isEmpty }))).sorted()
        guard !uniqueURLStrings.isEmpty else { return [] }

        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                continuation.resume(returning: uniqueURLStrings.map {
                    Self.makeSearchIndexSnapshot(urlString: $0, context: context)
                })
            }
        }
    }

    private func fetchAllHistoryItems() -> [HistoryItem] {
        let request = HistoryItem.createFetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \HistoryItem.time, ascending: false)
        ]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            Self.logger.error("Error while fetching all HistoryItems: \(error.localizedDescription)")
        }
        return []
    }

    private static func makeSearchIndexSnapshot(
        urlString: String,
        context: NSManagedObjectContext
    ) -> HistorySearchIndexSnapshot {
        guard let url = URL(string: urlString) else {
            return HistorySearchIndexSnapshot(urlString: urlString, entry: nil)
        }

        let request = HistoryItem.createFetchRequest()
        request.predicate = NSPredicate(format: "url == %@", url as CVarArg)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \HistoryItem.time, ascending: false)
        ]

        do {
            let items = try context.fetch(request)
            guard let latestItem = items.first else {
                return HistorySearchIndexSnapshot(urlString: urlString, entry: nil)
            }

            let title = items
                .compactMap(\.title)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty }) ?? ""
            let entry = HistoryEntry(
                id: UUID(),
                title: title,
                url: urlString,
                lastSeen: Int(latestItem.time.rounded()),
                amount: items.count
            )

            return HistorySearchIndexSnapshot(urlString: urlString, entry: entry)
        } catch {
            Self.logger.error("Error while creating History search index snapshot: \(error.localizedDescription)")
            return HistorySearchIndexSnapshot(urlString: urlString, entry: nil)
        }
    }
}
