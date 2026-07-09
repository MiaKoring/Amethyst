//
//  AmethystAppFunctions.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 30.11.24.
//

import SwiftUI
import MeiliSearch
import TipKit

extension AmethystApp {
    func onAppear() {
        do {
            try Tips.configure()
        } catch {}
        #if DEBUG
        appViewModel.showsSetup = true
        #else
        appViewModel.showsSetup = !UDKey.wasSetupOnce.boolValue
        #endif
        appViewModel.openWindow = { url in
            handleOpenSchema(url: url)
        }
        appViewModel.openMiniInNewTab = { url, id, focus in
            guard let contentViewModel = appViewModel.displayedWindows[id] else {
                appViewModel.newURLToOpen = url
                openWindow(id: "mainWindow")
                return
            }
            let id = UUID()
            let vm = WebViewModel(contentViewModel: contentViewModel, appViewModel: appViewModel, id: id)
            vm.load(urlString: url?.absoluteString ?? "")
            let tab = ATab(id: id, webViewModel: vm)
            contentViewModel.tabs.append(tab)
            if focus {
                contentViewModel.currentTab = tab.id
            }
        }
        appViewModel.openWindowByID = { id in
            openWindow(id: id)
        }
        do {
            let meiliURL = MeiliSettings.meiliURL.stringValue(default: "127.0.0.1:37270")
            guard !meiliURL.isEmpty else {
                print("Meili not setup")
                return
            }
            appViewModel.meili = try MeiliSearch(host: "http://\(meiliURL)", apiKey: KeyChainManager.getValue(for: .meiliMasterKey))
        } catch {
            print(error)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return handleAndPassCommand(event)
        }
    }
    func handleAndPassCommand(_ event: NSEvent) -> NSEvent? {
        if appViewModel.showsSetup { return event }
        if event.modifierFlags.rawValue == 256 || ((event.modifierFlags.contains(.shift) || event.modifierFlags.contains(.capsLock)) && (!event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.control) && !event.modifierFlags.contains(.option))) || appViewModel.currentlyActiveWindowId == "com_apple_SwiftUI_Settings_window" { return event }
        guard let keybind = Keybind(event) else { return event }
        guard keybind.execute(appViewModel: appViewModel, openWindow: openWindow) else {
            return nil
        }
        return event
    }
    
    func handleOpenSchema(url: URL) {
        if true { // TODO: Add setting
            openWindow(id: "singleWindow", value: url)
        } else {
            let id = appViewModel.currentlyActiveWindowId
            guard let latestFocused = appViewModel.displayedWindows[id] ?? appViewModel.displayedWindows.values.first else {
                appViewModel.newURLToOpen = url
                openWindow(id: "mainWindow")
                return
            }
            let uuid = UUID()
            let webVM = WebViewModel(contentViewModel: latestFocused, appViewModel: appViewModel, id: uuid)
            webVM.load(url: url)
            let tab = ATab(id: uuid, webViewModel: webVM)
            latestFocused.tabs.append(tab)
            latestFocused.currentTab = tab.id
            openWindow(id: latestFocused.id)
        }
    }
}

