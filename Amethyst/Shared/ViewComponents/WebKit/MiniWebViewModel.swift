//
//  MiniWebViewModel.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 30.11.24.
//

import SwiftUI
import WebKit
import Combine

@MainActor
class MiniWebViewModel: NSObject, ObservableObject {
    @Published var currentURL: URL? = nil
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var title: String? = nil
    @Published var isUsingCamera: WKMediaCaptureState = .none
    @Published var isUsingMicrophone: WKMediaCaptureState = .none
    @ObservedObject var appViewModel: AppViewModel
    
    private var webView: AWKWebView?
    private var cancellables: Set<AnyCancellable> = []
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        super.init()
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.1 Safari/605.1.15"
        webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        webConfiguration.allowsInlinePredictions = true
        webConfiguration.allowsAirPlayForMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webConfiguration.suppressesIncrementalRendering = false
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        self.webView = AWKWebView(frame: .zero, configuration: webConfiguration)
        self.webView?.allowsBackForwardNavigationGestures = false
        self.webView?.underPageBackgroundColor = .myPurple
        self.webView?.uiDelegate = self
        setupBindings()
    }
    
    func deinitialize() {
        DispatchQueue.main.async {
            Task {
                await self.webView?.pauseAllMediaPlayback()
                await self.webView?.closeAllMediaPresentations()
                await self.webView?.setCameraCaptureState(.none)
                await self.webView?.setMicrophoneCaptureState(.none)
                guard let url = URL(string: "https://bloombuddy.touchthegrass.de") else { return }
                self.webView?.load( URLRequest(url: url))
                self.cancellables.removeAll()
                self.webView?.configuration.userContentController.removeAllUserScripts()
                self.webView?.stopLoading()
                self.webView?.removeFromSuperview()
                
                self.webView?.navigationDelegate = nil
                self.webView?.uiDelegate = nil
                self.webView = nil
                print("deinitialized WebViewModel")
            }
        }
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
            let webConfiguration = WKWebViewConfiguration()
            webConfiguration.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.1 Safari/605.1.15"
            webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
            webConfiguration.allowsInlinePredictions = true
            webConfiguration.allowsAirPlayForMediaPlayback = true
            webConfiguration.mediaTypesRequiringUserActionForPlayback = []
            webConfiguration.suppressesIncrementalRendering = false
            let webView = AWKWebView(frame: .zero, configuration: webConfiguration)
            self.webView = webView
            self.webView?.allowsBackForwardNavigationGestures = false
            self.webView?.underPageBackgroundColor = .myPurple
            setupBindings()
    
            return webView
        }
    }
    
    func load(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.1 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        webView?.load(request)
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
                self?.currentURL = value
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
    }
}

extension MiniWebViewModel: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let url = navigationAction.request.url
        let windowToOpenIn = appViewModel.currentlyActiveWindowId
        
        if let customAction = (webView as? AWKWebView)?.contextualMenuAction {
            switch customAction {
            case .openInNewTab:
                guard let openFromMiniTab = appViewModel.openMiniInNewTab else { return nil }
                openFromMiniTab(url, windowToOpenIn, true)
                return nil
            case .openInBackground:
                guard let openFromMiniTab = appViewModel.openMiniInNewTab else { return nil }
                openFromMiniTab(url, windowToOpenIn, false)
                return nil
            case .openInNewWindow:
                guard let url, let open = appViewModel.openWindow else { return nil }
                open(url)
                return nil
            }
        } else if navigationAction.targetFrame == nil {
            guard let openFromMiniTab = appViewModel.openMiniInNewTab else { return nil }
            openFromMiniTab(url, windowToOpenIn, true)
            return nil
        } else {
            return nil
        }
    }
}

