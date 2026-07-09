
import SwiftUI

@MainActor
enum SearchSuggestionOrigin {
    case history
    case searchEngine
    case bang
    case command
}

extension SearchSuggestionOrigin {
    var image: Image {
        switch self {
            case .searchEngine:
                (SearchEngine(rawValue: UDKey.searchEngine.intValue) ?? .duckduckgo).icon
            case .history, .bang, .command:
                Image("AmethystLogo")
        }
    }
}
