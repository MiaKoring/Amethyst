//
//  HistoryVisitRow.swift
//  Amethyst Browser
//
//  Created by Codex on 28.03.26.
//

import Foundation

struct HistoryVisitRow: Identifiable {
    let item: HistoryItem
    let id: String
    let rawTitle: String?
    let displayTitle: String
    let url: URL
    let time: Double

    init?(item: HistoryItem) {
        guard let url = item.url else { return nil }

        let trimmedTitle = item.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackTitle = url.host ?? url.absoluteString

        self.item = item
        self.id = item.itemID?.uuidString ?? item.objectID.uriRepresentation().absoluteString
        self.rawTitle = (trimmedTitle?.isEmpty == false) ? trimmedTitle : nil
        self.displayTitle = rawTitle ?? fallbackTitle
        self.url = url
        self.time = item.time
    }

    var urlString: String {
        url.absoluteString
    }

    var host: String {
        url.host ?? url.absoluteString
    }
}
