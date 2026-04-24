//
//  WebViewModel.swift
//  Browser
//
//  Created by Mia Koring on 27.11.24.
//
import SwiftUI
import SwiftData
import WebKit
import Combine
import MeiliSearch
import AuthenticationServices

class WebViewModel: NSObject, ObservableObject {
    private static var accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var currentURL: URL? = nil
    @Published var isLoading: Bool = false
    @Published var title: String? = nil
    @Published var isUsingCamera: WKMediaCaptureState = .none
    @Published var isUsingMicrophone: WKMediaCaptureState = .none
    @Published var error: (any Error)? = nil
    @Published var blockDownloadCheckforURL: URL? = nil
    @Published var loadingProgress: Double = 0.0
    @ObservedObject var contentViewModel: ContentViewModel
    @ObservedObject var appViewModel: AppViewModel
    
    var referer: String? = nil
    
    var historyBlocked: [URL: Double] = [:]
    var webView: AWKWebView?
    var cancellables: Set<AnyCancellable> = []
    var cache: Bool? = nil
    
    // MARK: - Initializers

    // This is the new Designated Initializer. It's the most fundamental one.
    // It takes a fully prepared configuration and does the final setup.
    init(
        configuration: WKWebViewConfiguration,
        contentViewModel: ContentViewModel,
        appViewModel: AppViewModel
    ) {
        self.contentViewModel = contentViewModel
        self.appViewModel = appViewModel
        super.init()

        self.webView = AWKWebView(frame: .zero, configuration: configuration)
        self.configureWebView() // Centralized webView setup
        self.setupBindings()
        self.injectAllJS()
    }
    
    // Convenience init for a standard new tab.
    // It derives the processPool from the contentViewModel.
    convenience init(contentViewModel: ContentViewModel, appViewModel: AppViewModel) {
        let config = Self.makeDefaultConfiguration()
        // No special configuration needed, so we call the designated init directly.
        self.init(configuration: config, contentViewModel: contentViewModel, appViewModel: appViewModel)
    }
    
    init(config: WKWebViewConfiguration, contentViewModel: ContentViewModel, appViewModel: AppViewModel) {
        self.contentViewModel = contentViewModel
        self.appViewModel = appViewModel
        super.init()
        self.webView = AWKWebView(frame: .zero, configuration: config)
        self.webView?.allowsBackForwardNavigationGestures = false
        self.webView?.underPageBackgroundColor = .myPurple
        self.webView?.uiDelegate = self
        self.webView?.navigationDelegate = self
        self.webView?.allowsLinkPreview = true
        self.webView?.isInspectable = true
        
        setupBindings()
        injectAllJS()
    }
    
    deinit {
        webView?.stopLoading()
        
        let userContentController = webView?.configuration.userContentController
        userContentController?.removeAllUserScripts()
        userContentController?.removeScriptMessageHandler(forName: "webauthn")
        
        webView?.uiDelegate = nil
        webView?.navigationDelegate = nil
        
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        webView?.removeFromSuperview()
        webView = nil
    }
    
    func cleanup() async {
        // 1. Perform all async cleanup operations first.
        // We can safely await them here because we are in an async context
        // and the webView is guaranteed to still exist.
        await webView?.pauseAllMediaPlayback()
        await webView?.closeAllMediaPresentations()
        await webView?.setCameraCaptureState(.none)
        await webView?.setMicrophoneCaptureState(.none)

        // 2. Perform synchronous cleanup.
        // This part is similar to the deinit logic.
        webView?.stopLoading()
        webView?.load(URLRequest(url: URL(string: "about:blank")!))

        // 3. Break retain cycles. This is critical.
        let userContentController = webView?.configuration.userContentController
        userContentController?.removeAllUserScripts()

        webView?.uiDelegate = nil
        webView?.navigationDelegate = nil

        // 4. Clean up Combine subscriptions.
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        // 5. Remove from view hierarchy.
        webView?.removeFromSuperview()
        webView = nil
    }
    
    func goBack() {
        if canGoBack {
            webView?.goBack()
        }
    }
    
    func goForward() {
        if canGoForward {
            webView?.goForward()
        }
    }

    
    func getWebView() -> WKWebView {
        if let webView {
            return webView
        } else {
            let webConfiguration = Self.makeDefaultConfiguration()
            let webView = AWKWebView(frame: .zero, configuration: webConfiguration)
            self.webView = webView
            self.webView?.allowsBackForwardNavigationGestures = false
            self.webView?.underPageBackgroundColor = .myPurple
            self.webView?.allowsLinkPreview = true
            setupBindings()
    
            return webView
        }
    }
    
    func load(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        load(url: url)
    }
    
    func load(url: URL) {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.1 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue(Self.accept, forHTTPHeaderField: "Accept")
        webView?.load(request)
    }
    
    func appendHistory() {
        if let url = currentURL, cache != nil {
            if let blockedTime = historyBlocked[url], blockedTime > Date().timeIntervalSinceReferenceDate {
                return
            }
            if let meili = appViewModel.meili {
                addToHistory(meili: meili, url: url)
            }
            
            let day = CDHistoryController.currentHistoryDay
            let item = HistoryItem()
            item.time = Date.now.timeIntervalSinceReferenceDate
            item.url = url
            item.title = title
            day.addHistoryItem(item)
            CDHistoryController.save()
           
            historyBlocked[url] = Date.now.timeIntervalSinceReferenceDate + 300
        }
    }
    
    func addToHistory(meili: MeiliSearch, url: URL) {
        typealias MeiliResult = Searchable<HistoryEntry>
        SwiftUI.Task(priority: .background) {
            let index = meili.index("history")
            let param = SearchParameters(query: url.absoluteString, limit: 1, attributesToSearchOn: ["url"], filter: "url = '\(url.absoluteString)'")
            do {
                let result: MeiliResult = try await index.search(param)
                if let res = result.hits.first {
                    let new = HistoryEntry(id: res.id, title: self.title ?? res.title, url: res.url, lastSeen: Int(Date.now.timeIntervalSinceReferenceDate), amount: res.amount + 1)
                    _ = try await index.updateDocuments(documents: [new], primaryKey: "id")
                } else {
                    let new = HistoryEntry(id: UUID(), title: self.title ?? "", url: url.absoluteString, lastSeen: Int(Date.now.timeIntervalSinceReferenceDate), amount: 1)
                    _ = try await index.addDocuments(documents: [new], primaryKey: "id")
                }
            } catch let error as MeiliSearch.Error {
                Self.logger.error("Error occured while appending Meili history: \(error.localizedDescription)")
                if error.localizedDescription.contains("MeiliSearchApiError: Index `history` not found.") ||
                    error.localizedDescription.contains("is not filterable") ||
                    error.localizedDescription.contains("is not searchable") {
                    do {
                        _ = try await meili.createIndex(uid: "history", primaryKey: "id")
                        _ = try await meili.index("history").updateSearchableAttributes(["url", "title"])
                        _ = try await meili.index("history").updateFilterableAttributes(["url", "title", "id", "lastSeen", "amount"])
                        _ = try await meili.index("history").updateSortableAttributes(["lastSeen", "amount"])
                        let new = HistoryEntry(id: UUID(), title: self.title ?? "", url: url.absoluteString, lastSeen: Int(Date.now.timeIntervalSinceReferenceDate), amount: 1)
                        _ = try await index.addDocuments(documents: [new], primaryKey: "id")
                    } catch {
                        Self.logger.error("Error occured while configuring Meili index: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func setupBindings() {
        webView?.publisher(for: \.canGoBack)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.canGoBack = value
            }
            .store(in: &cancellables)

        webView?.publisher(for: \.canGoForward)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.canGoForward = value
            }
            .store(in: &cancellables)

        webView?.publisher(for: \.url)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                if let value {
                    self?.currentURL = value
                }
            }
            .store(in: &cancellables)

        webView?.publisher(for: \.isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isLoading = value
            }
            .store(in: &cancellables)

        webView?.publisher(for: \.title)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.title = value
            }
            .store(in: &cancellables)
        
        webView?.publisher(for: \.cameraCaptureState)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isUsingCamera = value
            }
            .store(in: &cancellables)
        
        webView?.publisher(for: \.microphoneCaptureState)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isUsingMicrophone = value
            }
            .store(in: &cancellables)
        
        webView?.publisher(for: \.estimatedProgress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.loadingProgress = value
            }
            .store(in: &cancellables)
    }
    
    private func injectAllJS() {
        injectJavaScript()
        injectCSSGlobally()
        injectAutofillCode()
    }
   
    // MARK: - Private Helper Methods

    /// Configures the common properties of the AWKWebView instance.
    private func configureWebView() {
        webView?.allowsBackForwardNavigationGestures = false
        webView?.underPageBackgroundColor = .myPurple
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
        webView?.allowsLinkPreview = true
        webView?.isInspectable = true // isInspectable was set twice, once is enough.
    }

    /// Factory method to create a default WKWebViewConfiguration for Amethyst.
    private static func makeDefaultConfiguration() -> WKWebViewConfiguration {
        let webConfiguration = WKWebViewConfiguration()
        // Set User-Agent
        webConfiguration.applicationNameForUserAgent =
            "Version/18.1.1 Safari/605.1.15"

        // Configure preferences
        let preferences = webConfiguration.preferences
        preferences.javaScriptCanOpenWindowsAutomatically = true
        preferences.isElementFullscreenEnabled = true
        preferences.isFraudulentWebsiteWarningEnabled = true
        preferences.isSiteSpecificQuirksModeEnabled = true

        // Configure default webpage preferences
        webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true

        // Configure webView behavior
        webConfiguration.allowsInlinePredictions = true
        webConfiguration.allowsAirPlayForMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webConfiguration.suppressesIncrementalRendering = false
        webConfiguration.upgradeKnownHostsToHTTPS = true

        // Data Store
        webConfiguration.websiteDataStore = WKWebsiteDataStore.default()

        // User Content Controller
        // The controller is created here, but handlers are added in the specific inits.
        webConfiguration.userContentController = WKUserContentController()

        return webConfiguration
    }
    
}

extension WebViewModel: WKScriptMessageHandlerWithReply {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        print(message.body)
        return (false, "whatever")
    }
    
    
}
