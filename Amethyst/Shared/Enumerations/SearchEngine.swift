//
//  SearchEngine.swift
//  Browser
//
//  Created by Mia Koring on 27.11.24.
//
import Foundation
import SwiftUI

@MainActor
enum SearchEngine: Int, CaseIterable {
    case duckduckgo
    case google
    case ecosia
    case startpage
}

extension SearchEngine: @MainActor Identifiable {
    var id: Int { self.rawValue }
    var logoName: String {
        switch self {
        case .duckduckgo:
            "ddgLogo"
        case .google:
            "googleLogo"
        case .ecosia:
            "ecosiaLogo"
        case .startpage:
            "startpageLogo"
        }
    }
    
    var icon: Image {
        switch self {
        case .duckduckgo:
            Image("ddgDuck")
        case .google:
            Image("googleIcon")
        case .ecosia:
            Image("ecosiaIcon")
        case .startpage:
            Image("spIcon")
        }
    }
    
    func makeSearchUrl(_ input: String) -> URL? {
        let query = input.addingPercentEncoding(withAllowedCharacters: []) ??
        input
        return switch self {
        case .duckduckgo:
            URL(string: "https://duckduckgo.com/?q=\(query)")
        case .google:
            URL(string: "https://google.com/search?q=\(query)")
        case .ecosia:
            URL(string: "https://www.ecosia.org/search?q=\(query)")
        case .startpage:
            URL(string: "https://www.startpage.com/sp/search?q=\(query)")
        }
    }
    
    func quickResults(_ input: String) async -> [String] {
        switch self {
        case .duckduckgo:
            await SEDuckDuckGo.quickResults(query: input)
        case .google:
            await SEGoogle.quickResults(query: input)
        default:
            await SEDuckDuckGo.quickResults(query: input)
        }
    }
    
    var root: String {
        switch self {
        case .duckduckgo:
            "https://duckduckgo.com"
        case .google:
            "https://google.com"
        case .ecosia:
            "https://www.ecosia.org"
        case .startpage:
            "https://www.startpage.com"
        }
    }
}
