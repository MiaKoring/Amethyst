//
//  AppViewModel.swift
//  Browser
//
//  Created by Mia Koring on 27.11.24.
//
import SwiftData
import SwiftUI
import WebKit
import MeiliSearch


@Observable
class AppViewModel: NSObject, ObservableObject, NSWindowDelegate {
    var currentlyActiveWindowId: String = ""
    var displayedWindows = [String: ContentViewModel]()
    var openWindow: ((URL) -> Void)? = nil
    var openWindowByID: ((String) -> Void)? = nil
    var openMiniInNewTab: ((URL?, String, Bool) -> Void)? = nil
    var highlightedWindow: String = ""
    var showsSetup = false
    var meili: MeiliSearch?
    var shouldSkipMeiliNotification: Bool = false
    var downloadManager: DownloadManager?
    var useMacOS26Design = !UDKey.useOldDesign.boolValue
    var newURLToOpen: URL?
    var createNewWindow: Bool = false
    var runsInAppStoreSandbox: Bool = false
    
    let standardFileImage: Image
    
    override init() {
        standardFileImage = Image(nsImage: NSWorkspace.shared.icon(for: .data))
        super.init()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if let id = window.identifier?.rawValue {
                currentlyActiveWindowId = id
            }
        }
    }
    
    static func isDefaultBrowser() -> Bool {
        guard let url = URL(string: "https://amethystbrowser.de"), let appURL = NSWorkspace.shared.urlForApplication(toOpen: url) else { return false }
        
        return appURL.absoluteString.contains("Amethyst%20Browser.app")
    }
    
    
}
