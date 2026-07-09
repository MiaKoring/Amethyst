//
//  AppDelegate.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 30.11.24.
//
import SwiftData
import SwiftUI
import WebKit
import OSLog

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var appViewModel: AppViewModel?
    private static var logger = Logger(subsystem: AmethystApp.subSystem, category: "AppDelegate")
    private var launchedViaURL = false
    
    static let settingsGroupID: String = {
        guard let teamID = Bundle.main.object(forInfoDictionaryKey: "TeamID") as? String else { fatalError("TeamID not found")}
        return "\(teamID)group.de.touchthegrass.Amethyst.Index"
    }()
    
    func configure(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let appViewModel else { return .terminateNow }
        CDTabController.clear()
        
        for contentViewModel in appViewModel.displayedWindows.values {
            insert(valuesOf: contentViewModel, id: contentViewModel.id)
        }
        
        Self.logger.info("about to save tab changes")
        Self.logger.info("Container has changes: \(CDTabController.shared.container.viewContext.hasChanges)")
        CDTabController.save()
        Self.logger.info("tabs saved")
        Self.logger.info("Container has changes after saving: \(CDTabController.shared.container.viewContext.hasChanges)")
        return .terminateNow
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        BangManager.shared.fetch()
        CommandsManager.shared.fetch()
        Task { @MainActor in
            let hasVisibleContentWindows = NSApp.windows.contains { window in
                window.isVisible && window.canBecomeMain
            }
            
            if !hasVisibleContentWindows {
                self.appViewModel?.createNewWindow.toggle()
            }
        }
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        self.launchedViaURL = true
        Self.logger.warning("trying to open url")
        guard let url = urls.first else { return }
        if let appVMopenWindow = appViewModel?.openWindow {
            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(500))) {
                print("called handle")
                appVMopenWindow(url)
            }
        } else {
            Self.logger.error("failed to open url")
        }
    }
    
    
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            return true
        }
        var miniaturizedWindow: NSWindow? = nil
        let shouldRestoreMiniaturized = !sender.windows.contains(where: {!$0.isMiniaturized})
        if shouldRestoreMiniaturized {
            for window in sender.windows {
                if window.identifier?.rawValue.hasPrefix("mainWindow") ?? false,
                   window.isMiniaturized,
                   miniaturizedWindow == nil {
                    miniaturizedWindow = window
                }
            }
            guard let window = miniaturizedWindow else { return true }
            window.deminiaturize(nil)
        }
        return false
    }
    
    private func insert(valuesOf values: ContentViewModel, id: String) {
        for i in 0..<values.tabs.count {
            let tab = values.tabs[i]
            
            let newTab = SavedTab()
            newTab.tabID = tab.id
            newTab.sortingID = Int16(i)
            newTab.url = tab.webViewModel.currentURL
            newTab.windowID = id
            
            CDTabController.insertSavedTab(newTab)
        }
    }
    
}

