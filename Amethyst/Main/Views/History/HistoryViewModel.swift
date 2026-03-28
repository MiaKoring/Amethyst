//
//  HistoryViewModel.swift
//  Amethyst Browser
//
//  Created by Codex on 28.03.26.
//

import MeiliSearch
import SwiftUI

@MainActor
@Observable
final class HistoryViewModel {
    var searchText = "" {
        didSet {
            applyFilters()
        }
    }

    var sections = [HistoryDaySection]()
    var expandedPageIDs = Set<String>()
    var pendingPageDeletion: HistoryGroupedPage?
    var showClearAllConfirmation = false

    private var allSections = [HistoryDaySection]()

    var hasHistory: Bool {
        !allSections.isEmpty
    }

    var hasSearchResults: Bool {
        !sections.isEmpty
    }

    var resultCount: Int {
        sections.reduce(into: 0) { partialResult, section in
            partialResult += section.pages.count
        }
    }

    func load() {
        allSections = makeSections(days: CDHistoryController.fetchAllHistoryDays())
        applyFilters()
    }

    func deleteVisit(_ visit: HistoryVisitRow, meili: MeiliSearch?) {
        CDHistoryController.delete(visit.item)
        HistorySearchIndexSync.syncExactURLStrings([visit.urlString], meili: meili)
        load()
    }

    func confirmDeletePage(_ page: HistoryGroupedPage) {
        pendingPageDeletion = page
    }

    func deletePendingPage(meili: MeiliSearch?) {
        guard let pendingPageDeletion else { return }

        let affectedURLStrings = CDHistoryController.deleteAllVisits(matchingCanonicalURL: pendingPageDeletion.canonicalURL)
        self.pendingPageDeletion = nil
        HistorySearchIndexSync.syncExactURLStrings(affectedURLStrings, meili: meili)
        load()
    }

    func dismissPendingPageDeletion() {
        pendingPageDeletion = nil
    }

    func clearAllHistory(meili: MeiliSearch?) {
        CDHistoryController.clear()
        showClearAllConfirmation = false
        pendingPageDeletion = nil
        expandedPageIDs.removeAll()
        HistorySearchIndexSync.clearAll(meili: meili)
        load()
    }

    private func makeSections(days: [HistoryDay]) -> [HistoryDaySection] {
        days.compactMap { day in
            let groupedPages = Dictionary(grouping: day.sortedItems.compactMap(HistoryVisitRow.init(item:))) { visit in
                HistoryCanonicalizer.canonicalURLString(for: visit.url)
            }
            .map { key, visits in
                HistoryGroupedPage(dayTime: day.dayTime, canonicalURL: key, visits: visits)
            }
            .sorted(by: { $0.lastVisitedTime > $1.lastVisitedTime })

            guard !groupedPages.isEmpty else { return nil }
            return HistoryDaySection(dayTime: day.dayTime, pages: groupedPages)
        }
    }

    private func applyFilters() {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedSearch.isEmpty {
            sections = allSections
        } else {
            sections = allSections.compactMap { section in
                let matchingPages = section.pages.filter { $0.matches(searchText: trimmedSearch) }
                guard !matchingPages.isEmpty else { return nil }
                return HistoryDaySection(dayTime: section.dayTime, pages: matchingPages)
            }
        }

        let visiblePageIDs = Set(sections.flatMap { $0.pages.map(\.id) })
        expandedPageIDs = expandedPageIDs.intersection(visiblePageIDs)
    }
}
