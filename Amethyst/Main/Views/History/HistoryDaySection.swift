//
//  HistoryDaySection.swift
//  Amethyst Browser
//
//  Created by Codex on 28.03.26.
//

import Foundation

struct HistoryDaySection: Identifiable {
    let dayTime: Double
    let pages: [HistoryGroupedPage]

    var id: Double {
        dayTime
    }

    var title: String {
        Date(timeIntervalSinceReferenceDate: dayTime).formatted(date: .numeric, time: .omitted)
    }
}
