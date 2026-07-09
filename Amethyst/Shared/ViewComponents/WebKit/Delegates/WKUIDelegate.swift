//
//  WKUIDelegate.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 04.12.24.
//
import WebKit

extension WebViewModel: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        // TODO: handle targetframe nil as open separate small context login type window
        
        if let customAction = (webView as? AWKWebView)?.contextualMenuAction {
            switch customAction {
                case .openInNewTab:
                    return openInNewTab(configuration: configuration)
                case .openInBackground:
                    let newWebViewModel = WebViewModel(config: configuration, contentViewModel: contentViewModel, appViewModel: appViewModel)
                    let newTab = ATab(webViewModel: newWebViewModel)
                    contentViewModel.tabs.append(newTab)
                    
                    backgroundTabCreatedOverlayTimer?.invalidate()
                    backgroundTabCreatedOverlayTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] timer in
                        timer.invalidate()
                        self?.backgroundTabCreatedOverlayTimer = nil
                    }
                return newWebViewModel.webView
            case .openInNewWindow:
                guard let url = navigationAction.request.url, let open = appViewModel.openWindowByID else { return nil }
                appViewModel.newURLToOpen = url
                open("mainWindow")
                return nil
            }
        } else if navigationAction.targetFrame == nil && !navigationAction.shouldPerformDownload {
            return openInNewTab(configuration: configuration)
        } else {
            return nil
        }
    }
    
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo) async -> [URL]? {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection
        
        let response = await openPanel.begin()

        if response == .OK {
            return openPanel.urls
        } else {
            return nil
        }
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = message
        
        if let window = webView.window {
            await alert.beginSheetModal(for: window)
            return
        }
        alert.runModal()
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async -> Bool {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.layout()
        
        var response: NSApplication.ModalResponse
        
        if let window = webView.window {
            response = await alert.beginSheetModal(for: window)
        } else {
            response = alert.runModal()
        }
        
        return response == .alertFirstButtonReturn
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (String?) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = prompt
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        inputField.stringValue = defaultText ?? ""
        alert.accessoryView = inputField
        
        alert.layout()
        alert.window.initialFirstResponder = inputField
        
        if let window = webView.window {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    completionHandler(inputField.stringValue)
                } else {
                    completionHandler(nil)
                }
            }
            return
        }
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completionHandler(inputField.stringValue)
        } else {
            completionHandler(nil)
        }
    }
    
    private func openInNewTab(configuration: WKWebViewConfiguration) -> WKWebView? {
        let newWebViewModel = WebViewModel(config: configuration, contentViewModel: contentViewModel, appViewModel: appViewModel)
        let newTab = ATab(webViewModel: newWebViewModel)
        if let index = contentViewModel.tabs.firstIndex(where: {$0.id == contentViewModel.currentTab}) {
            contentViewModel.tabs.insert(newTab, at: index + 1)
        } else {
            contentViewModel.tabs.append(newTab)
        }
        contentViewModel.currentTab = newTab.id
        return newWebViewModel.webView
    }
}
