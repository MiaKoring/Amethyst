//
//  InputBarFunctions.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 02.12.24.
//
import Foundation
@preconcurrency import MeiliSearch
import SwiftUI

@MainActor
extension InputBar {
    func timerSuggestionFetch() async {
        if let bang = BangManager.shared.resolve(text) {
            quickSearchResults = [SearchSuggestion(title: text, urlString: bang, origin: .bang)]
            return
        }
        if let command = CommandsManager.shared.resolve(text) {
            quickSearchResults = [SearchSuggestion(title: text, urlString: command, origin: .command)]
            return
        }
        if let meili = appViewModel.meili {
            let results = await fetchSearchEngineSuggestions()
            let meiliRes = await fetchHistorySuggestions(meili)
            makeResult(searchEngineList: results, meiliList: meiliRes)
        } else {
            let results = await fetchSearchEngineSuggestions()
            makeResult(searchEngineList: results, meiliList: nil)
        }
    }
    
    private func fetchSearchEngineSuggestions() async -> [SearchSuggestion] {
        let searchEngine = SearchEngine(rawValue: UDKey.searchEngine.intValue) ?? .duckduckgo
        let searchEngineItems = await searchEngine.quickResults(text)
        
        let results = Array(searchEngineItems.prefix(Self.suggestionItemMaxCount)).sorted(by: {
            let a = $0.wholeMatch(of: Regexpr.urlWithoutProtocol.regex)
            let b = $1.wholeMatch(of: Regexpr.urlWithoutProtocol.regex)
            return a != nil && b == nil
        }).map({
            if let _ = $0.wholeMatch(of: Regexpr.urlWithoutProtocol.regex) {
                SearchSuggestion(title: $0, urlString: "https://\($0)", origin: .searchEngine)
            } else {
                SearchSuggestion(title: $0, urlString: "\(searchEngine.makeSearchUrl($0)?.absoluteString ?? searchEngine.root)", origin: .searchEngine)
            }
        })
        return results
    }
    
    private func fetchHistorySuggestions(_ meili: MeiliSearch) async -> [SearchSuggestion] {
        let query = text
        let hits: [SearchHit<HistoryEntryResult>] = await {
            do {
                let params = SearchParameters(
                    query: query,
                    limit: 5,
                    attributesToSearchOn: ["title", "url"],
                    sort: ["amount:desc", "lastSeen:desc"],
                    showRankingScore: true
                )
                let res: Searchable<HistoryEntryResult> = try await meili.index("history").search(params)
                return res.hits
            } catch {
                return []
            }
        }()
        
        return hits.compactMap { hit in
            if (hit._rankingScore ?? 0) > 0.6 {
                return SearchSuggestion(
                    title: hit.title.isEmpty ? hit.url : hit.title,
                    urlString: hit.url,
                    origin: .history
                )
            }
            return nil
        }
    }
    
    private func makeResult(
        searchEngineList: [SearchSuggestion],
        meiliList: [SearchSuggestion]?
    ) {
        var result: [SearchSuggestion] = []
        if let meiliList {
            if searchEngineList.count >= 1 {
                result = Array(meiliList.prefix(Self.suggestionItemMaxCount - Self.suggestionItemMaxCount / 2))
            } else {
                result = Array(meiliList.prefix(Self.suggestionItemMaxCount))
            }
        }
        for i in 0..<searchEngineList.count {
            if result.count < Self.suggestionItemMaxCount {
                result.append(searchEngineList[i])
            } else {
                quickSearchResults = result
                return
            }
        }
        quickSearchResults = result
    }
    
    func updateSelection(up: Bool = true) {
        let currentIndex = selectedResult
        if up {
            let index = currentIndex - 1 >= 0 ? currentIndex - 1: quickSearchResults.count
            selectedResult = index
        } else {
            let index = currentIndex + 1 < quickSearchResults.count + 1 ? currentIndex + 1: 0
            selectedResult = index
        }
    }
}
