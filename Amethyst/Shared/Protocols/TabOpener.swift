//
//  TabOpener.swift
//  Amethyst
//
//  Created by Mia Koring on 28.11.24.
//
import SwiftData
import SwiftUI
import WebKit
import OSLog

@MainActor
protocol TabOpener {
    var contentViewModel: ContentViewModel { get }
    var appViewModel: AppViewModel { get }
    var dismissWindow: DismissWindowAction { get }
    static var logger: Logger { get }
}

extension TabOpener {
    func handleInputBarSubmit(text: String, tabID: UUID? = nil) {
        let inputType = InputParser.parse(text)
        
        switch inputType {
        case .command(.quit): dismissWindow()
        case .command(.clearTabs):
            contentViewModel.tabs = []
            contentViewModel.currentTab = nil
        case .url(let url):
            openOrUpdateTab(with: url, forTabID: tabID)
        case .searchQuery(let query):
            let searchEngine =
            SearchEngine(rawValue: UDKey.searchEngine.intValue) ?? .duckduckgo
            if let url = searchEngine.makeSearchUrl(query) {
                openOrUpdateTab(with: url, forTabID: tabID)
            } else {
                Self.logger.error("Could not create search URL for query: \(query)")
            }
        }
    }
    
    private func openOrUpdateTab(with url: URL, forTabID tabID: UUID?) {
        // If a tabID is provided, find the existing tab and load the URL.
        if let tabID = tabID,
           let index = contentViewModel.tabs.firstIndex(where: { $0.id == tabID })
        {
            let webViewModel = contentViewModel.tabs[index].webViewModel
            webViewModel.load(url: url)
        } else {
            let id = UUID()
            // Otherwise, create a new tab.
            let webViewModel = WebViewModel(
                contentViewModel: contentViewModel,
                appViewModel: appViewModel,
                id: id
            )
            
            webViewModel.load(url: url)
            
            let newTab = ATab(id: id, webViewModel: webViewModel)
            contentViewModel.tabs.append(newTab)
            contentViewModel.currentTab = newTab.id
        }
    }
}

fileprivate enum InputType {
    // Represents a special command like :q or :clear
    enum Command: String {
        case quit = ":q"
        case clearTabs = ":clear"
    }

    case command(Command)
    case url(URL)
    case searchQuery(String)
}

@MainActor
fileprivate struct InputParser {
    static func parse(_ text: String) -> InputType {
        // First, check for special commands
        if let command = InputType.Command(rawValue: text) {
            return .command(command)
        }
        
        var text = text
        
        if let bangResult = BangManager.shared.resolve(text) {
            text = bangResult
        }
        
        if let shortcut = CommandsManager.shared.resolve(text) {
            text = shortcut
        }

        // Then, try to interpret the text as a URL
        if let url = createURL(from: text) {
            return .url(url)
        }

        // If it's not a command or a valid URL, it's a search query.
        return .searchQuery(text)
    }

    // This helper function centralizes the logic for creating a URL from various string formats.
    private static func createURL(from text: String) -> URL? {
        var potentialURLString = text

        // Handle localhost specifically by replacing it with the loopback IP.
        if potentialURLString.contains("localhost") {
            potentialURLString = potentialURLString.replacingOccurrences(
                of: "localhost",
                with: "127.0.0.1"
            )
        }

        // Check if the string already has a scheme (http, https, etc.)
        let hasScheme =
            potentialURLString.wholeMatch(of: Regexpr.url.regex) != nil ||
            potentialURLString.wholeMatch(of: Regexpr.ip.regex) != nil

        if hasScheme {
            return URL(string: potentialURLString)
        }

        // Check for URLs without a scheme and prepend "https://".
        // This is safer and more robust than just prepending "http://".
        let isURLWithoutScheme =
            potentialURLString.wholeMatch(of: Regexpr.urlWithoutProtocol.regex) != nil ||
            potentialURLString.wholeMatch(of: Regexpr.ipWithoutProtocol.regex) != nil

        if isURLWithoutScheme {
            return URL(string: "https://\(potentialURLString)")
        }

        // If none of the above, it's not a direct URL.
        return nil
    }
}
