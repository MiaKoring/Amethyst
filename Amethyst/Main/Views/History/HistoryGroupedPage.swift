//
//  HistoryGroupedPage.swift
//  Amethyst Browser
//
//  Created by Codex on 28.03.26.
//

import Foundation

struct HistoryGroupedPage: Identifiable {
    let dayTime: Double
    let canonicalURL: String
    let visits: [HistoryVisitRow]

    init(dayTime: Double, canonicalURL: String, visits: [HistoryVisitRow]) {
        self.dayTime = dayTime
        self.canonicalURL = canonicalURL
        self.visits = visits.sorted(by: { $0.time > $1.time })
    }

    var id: String {
        "\(dayTime)|\(canonicalURL)"
    }

    var latestVisit: HistoryVisitRow {
        visits[0]
    }

    var displayTitle: String {
        visits.first(where: { $0.rawTitle != nil })?.displayTitle ?? latestVisit.displayTitle
    }

    var displayURL: String {
        latestVisit.urlString
    }

    var host: String {
        latestVisit.host
    }

    var lastVisitedTime: Double {
        latestVisit.time
    }

    var visitCount: Int {
        visits.count
    }

    func matches(searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }

        if displayTitle.localizedCaseInsensitiveContains(searchText) || host.localizedCaseInsensitiveContains(searchText) {
            return true
        }

        return visits.contains(where: {
            $0.urlString.localizedCaseInsensitiveContains(searchText) ||
            ($0.rawTitle?.localizedCaseInsensitiveContains(searchText) ?? false)
        })
    }
}
