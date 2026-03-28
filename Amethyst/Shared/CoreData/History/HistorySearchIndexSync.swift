//
//  HistorySearchIndexSync.swift
//  Amethyst Browser
//
//  Created by Codex on 28.03.26.
//

import Foundation
import MeiliSearch
import OSLog

enum HistorySearchIndexSync {
    private static let historyIndexUID = "history"
    private static let logger = Logger(subsystem: AmethystApp.subSystem, category: "HistorySearchIndexSync")

    static func syncExactURLStrings(_ urlStrings: [String], meili: MeiliSearch?) {
        guard let meili else { return }

        let uniqueURLStrings = Array(Set(urlStrings.filter({ !$0.isEmpty }))).sorted()
        guard !uniqueURLStrings.isEmpty else { return }

        Swift.Task(priority: .background) {
            let snapshots = await CDHistoryController.fetchSearchIndexSnapshots(for: uniqueURLStrings)
            await performWithPreparedIndex(meili: meili, createIfMissing: true) { index in
                for snapshot in snapshots {
                    let existingEntries = try await fetchEntries(urlString: snapshot.urlString, index: index)
                    try await sync(snapshot: snapshot, existingEntries: existingEntries, index: index)
                }
            }
        }
    }

    static func clearAll(meili: MeiliSearch?) {
        guard let meili else { return }

        Swift.Task(priority: .background) {
            let index = meili.index(historyIndexUID)
            do {
                _ = try await index.deleteAllDocuments()
            } catch let error as MeiliSearch.Error {
                if shouldPrepareIndex(for: error) {
                    return
                }
                logger.error("Failed clearing Meili history index: \(error.localizedDescription)")
            } catch {
                logger.error("Failed clearing Meili history index: \(error.localizedDescription)")
            }
        }
    }

    private static func sync(
        snapshot: HistorySearchIndexSnapshot,
        existingEntries: [SearchHit<HistoryEntryResult>],
        index: Indexes
    ) async throws {
        if let entry = snapshot.entry {
            let documentID = existingEntries.first?.id ?? entry.id
            let syncedEntry = HistoryEntry(
                id: documentID,
                title: entry.title,
                url: entry.url,
                lastSeen: entry.lastSeen,
                amount: entry.amount
            )

            if existingEntries.isEmpty {
                _ = try await index.addDocuments(documents: [syncedEntry], primaryKey: "id")
            } else {
                _ = try await index.updateDocuments(documents: [syncedEntry], primaryKey: "id")
            }

            let duplicateIDs = existingEntries.dropFirst().map { $0.id.uuidString }
            if !duplicateIDs.isEmpty {
                _ = try await index.deleteBatchDocuments(duplicateIDs)
            }
        } else {
            let existingIDs = existingEntries.map { $0.id.uuidString }
            if !existingIDs.isEmpty {
                _ = try await index.deleteBatchDocuments(existingIDs)
            }
        }
    }

    private static func fetchEntries(
        urlString: String,
        index: Indexes
    ) async throws -> [SearchHit<HistoryEntryResult>] {
        let searchResult: Searchable<HistoryEntryResult> = try await index.search(SearchParameters(
            query: urlString,
            limit: 20,
            attributesToSearchOn: ["url"],
            filter: "url = '\(escapedFilterValue(urlString))'"
        ))
        return searchResult.hits
    }

    private static func performWithPreparedIndex(
        meili: MeiliSearch,
        createIfMissing: Bool,
        operation: @escaping (Indexes) async throws -> Void
    ) async {
        let index = meili.index(historyIndexUID)
        do {
            try await operation(index)
        } catch let error as MeiliSearch.Error {
            guard createIfMissing, shouldPrepareIndex(for: error) else {
                logger.error("Failed syncing Meili history index: \(error.localizedDescription)")
                return
            }

            do {
                try await prepareIndex(meili)
                try await operation(index)
            } catch let retryError as MeiliSearch.Error {
                logger.error("Failed syncing Meili history index after reconfiguring index: \(retryError.localizedDescription)")
            } catch {
                logger.error("Failed syncing Meili history index after reconfiguring index: \(error.localizedDescription)")
            }
        } catch {
            logger.error("Failed syncing Meili history index: \(error.localizedDescription)")
        }
    }

    private static func prepareIndex(_ meili: MeiliSearch) async throws {
        do {
            _ = try await meili.createIndex(uid: historyIndexUID, primaryKey: "id")
        } catch let error as MeiliSearch.Error {
            let description = error.localizedDescription
            if !description.contains("already exists") && !description.contains("already in use") {
                throw error
            }
        }

        let index = meili.index(historyIndexUID)
        _ = try await index.updateSearchableAttributes(["url", "title"])
        _ = try await index.updateFilterableAttributes(["url", "title", "id", "lastSeen", "amount"])
        _ = try await index.updateSortableAttributes(["lastSeen", "amount"])
    }

    private static func shouldPrepareIndex(for error: MeiliSearch.Error) -> Bool {
        let description = error.localizedDescription
        return description.contains("Index `history` not found") ||
        description.contains("is not filterable") ||
        description.contains("is not searchable")
    }

    private static func escapedFilterValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
    }
}
