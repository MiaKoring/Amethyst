//
//  PasswordListModel.swift
//  Amethyst Project
//
//  Created by Mia Koring on 04.06.25.
//

import SwiftUI
import SwiftData
import AmethystAuthenticatorCore
import OSLog

@MainActor
struct PasswordList {
    @Environment(ContentViewModel.self) var contentViewModel
    @Environment(PasswordSortData.self) var sortData
    @Query var accounts: [Account]
    @State var searchText: String = ""
    var context: ModelContext
    @State var identifiers = Set<String>()
    @State var showAccountCreation: Bool = false
    @State var currentTabWebViewModel: WebViewModel? = nil
    
    @State var likelyAccounts: [Account] = []
    @State var remainingAccounts: [Account] = []
    static let logger = Logger(subsystem: AmethystApp.subSystem, category: "PasswordList")
    
    @State var filterDebounceTimer: Task<Void, Never>?
    
    func scheduleFilterUpdate(debounceTime: CGFloat = 0.5) {
        filterDebounceTimer?.cancel()
        filterDebounceTimer = Task {
            do {
                try await Task.sleep(for: .seconds(debounceTime))
                Self.logger.debug("Debounced filter triggered")
                filterAccounts()
            } catch { }
        }
    }
    
    func filterAccounts() {
        var likely = [Account]()
        var remaining = [Account]()
        
        for account in accounts {
            let (passedLikely, passedRemaining) = passesFilter(account)
            if passedLikely {
                likely.append(account)
            } else if passedRemaining {
                remaining.append(account)
            }
        }
        likelyAccounts = likely
        remainingAccounts = remaining.sorted(by: { sortData.filter.shouldPrecede(lhs: $0, rhs: $1, ascending: sortData.ascending) })
    }
    
    func passesFilter(_ account: Account) -> (likely: Bool, remaining: Bool) {
        let passesDeletedFilter = account.deletedAt == nil
        
        let passesSearchFilter = searchText.isEmpty ||
                                account.username.localizedCaseInsensitiveContains(searchText) ||
                                account.service.localizedCaseInsensitiveContains(searchText) ||
                                account.title?.localizedCaseInsensitiveContains(searchText) ?? false
        
        let matchingIdentifier = identifiers.contains(where: { identifier in
            account.aliases.contains(where: { alias in
                alias.contains(identifier)
            }) ||
            account.service.contains(identifier)
        })
        
        let passesCommonFilters = (passesDeletedFilter && passesSearchFilter)
        return (
            likely: passesCommonFilters && matchingIdentifier,
            remaining: passesCommonFilters
        )
    }
    
    func setIdentifiersForCurrentTab(initial: Bool = false) {
        guard let currentTabId = contentViewModel.currentTab, let tab = contentViewModel.tabs.first(where: { tab in
            tab.id == currentTabId
        }) else {
            if !identifiers.isEmpty || initial {
                identifiers = Set<String>()
                scheduleFilterUpdate(debounceTime: initial ? 0.05: 0.5)
            }
            currentTabWebViewModel = nil
            return
        }
        currentTabWebViewModel = tab.webViewModel
        guard let webViewModel = currentTabWebViewModel,  let url = webViewModel.currentURL else {
            if !identifiers.isEmpty {
                identifiers = Set<String>()
                scheduleFilterUpdate(debounceTime: initial ? 0.05: 0.5)
            }
            return
        }
        let newIdentifiers = IdentifierHandler.getIdentifiers(urlString: url.absoluteString)
        if identifiers != newIdentifiers {
            identifiers = newIdentifiers
            scheduleFilterUpdate(debounceTime: initial ? 0.05: 0.5)
        }
    }
    
    func updateIdentifiersFromURL() {
        guard let webViewModel = currentTabWebViewModel, let url = webViewModel.currentURL else {
            if !identifiers.isEmpty {
                identifiers = Set<String>()
                scheduleFilterUpdate()
            }
            return
        }
        let newIdentifiers = IdentifierHandler.getIdentifiers(urlString: url.absoluteString)
        if identifiers != newIdentifiers {
            identifiers = newIdentifiers
            scheduleFilterUpdate() // Identifier haben sich geändert
        }
    }
    
    func autofill(username: String, password: String?) {
        if let webView = currentTabWebViewModel?.webView {
            let username = escapeStringForJavaScript(username)
            let password = escapeStringForJavaScript(password ?? "")
            webView.evaluateJavaScript("amethystAutofillCredentials(\(username), \(password));")
            Self.logger.debug("autofill called")
        } else {
            Self.logger.debug("webView is nil")
        }
    }
    
    private func escapeStringForJavaScript(_ string: String) -> String {
        if string.isEmpty { return "\"\"" }
        do {
            let data = try JSONEncoder().encode(string)
            
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw NSError(
                    domain: "JavaScriptEscapeError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON data to string for JavaScript escaping."]
                )
            }
            return jsonString
        } catch {
            Self.logger.debug("\(error.localizedDescription)")
            return "\"\""
        }
    }
}

