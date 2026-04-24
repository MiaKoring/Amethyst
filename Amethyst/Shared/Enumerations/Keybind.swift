//
//  Keybind.swift
//  Amethyst Project
//
//  Created by Mia Koring on 11.06.25.
//
import SwiftUI

enum Keybind: String, CaseIterable, UserDefaultWrapper {
    case newWindow
    case toggleSidebar
    case toggleSidebarFixed
    case togglePasswords
    case togglePasswordsFixed
    case openSearchbar
    case openInlineSearch
    case previousTab
    case nextTab
    case goBack
    case goForward
    case reload
    case reloadFromSource
    case closeCurrentTab
    case showHistory
    case zoomIn
    case zoomOut
    case resetZoom
    case triggerPasswordsAuth
    case sidebarOrientation
    case moveSingleFrameToWindow
    case toggleTranslucentFloatingWindow
}

extension Keybind {
    init?(_ event: NSEvent) {
        guard let keybind = Keybind.allCases.first(where: { keybind in
            Keybind.expectedShortcutMatchesEvent(expected: keybind.keyboardShortcut, event: event)
        }) else {
            return nil
        }
        self = keybind
    }
    
    // A thread-safe, in-memory cache for the decoded shortcuts.
    static var shortcutCache: [String: Shortcut] = [:]

    // A serial dispatch queue to ensure thread-safe access to the cache.
    static let cacheQueue = DispatchQueue(
        label: "com.amethyst.browser.keybinds.cacheQueue"
    )
    private static func expectedShortcutMatchesEvent(expected: KeyboardShortcut, event: NSEvent) -> Bool {
        return event.characters?.first?.lowercased() == expected.key.character.lowercased() &&
        (event.modifierFlags.contains(.control) == expected.modifiers.contains(.control)) && (event.modifierFlags.contains(.command) == expected.modifiers.contains(.command)) && (event.modifierFlags.contains(.shift) == expected.modifiers.contains(.shift)) && (event.modifierFlags.contains(.capsLock) == expected.modifiers.contains(.capsLock)) && (event.modifierFlags.contains(.option) == expected.modifiers.contains(.option))
    }
    
    var shortcut: Shortcut {
        get {
            // First, try to retrieve the shortcut from the cache in a thread-safe way.
            let cachedShortcut = Keybind.cacheQueue.sync {
                Keybind.shortcutCache[self.rawValue]
            }
            
            if let shortcut = cachedShortcut {
                // Cache hit: return the cached shortcut immediately.
                return shortcut
            }
            
            // Cache miss: The shortcut is not in our cache yet.
            // We need to compute it from UserDefaults.
            let computedShortcut: Shortcut
            if let data = self.data,
               let decoded = try? JSONDecoder().decode(
                Shortcut.self,
                from: data
               )
            {
                // A custom shortcut was found in UserDefaults.
                computedShortcut = decoded
            } else {
                // No custom shortcut found, use the default.
                computedShortcut = self.defaultShortcut
            }
            
            // Store the newly computed shortcut in the cache for next time.
            Keybind.cacheQueue.sync {
                Keybind.shortcutCache[self.rawValue] = computedShortcut
            }
            
            return computedShortcut
        }
        nonmutating set {
            do {
                // Encode the new shortcut and save it to UserDefaults.
                let encoded = try JSONEncoder().encode(newValue)
                UserDefaults.standard.set(encoded, forKey: self.key)
                
                // Update the cache with the new value in a thread-safe way.
                Keybind.cacheQueue.sync {
                    Keybind.shortcutCache[self.rawValue] = newValue
                }
            } catch {
                print("Error encoding shortcut: \(error)")
            }
        }
    }
    
    var defaultShortcut: Shortcut {
        switch self {
        case .newWindow:
            Shortcut(key: "n", modifier: .command)
        case .toggleSidebar:
            Shortcut(key: "e", modifier: .command)
        case .toggleSidebarFixed:
            Shortcut(key: "e", modifier: [.command, .shift])
        case .togglePasswords:
            Shortcut(key: "p", modifier: .command)
        case .togglePasswordsFixed:
            Shortcut(key: "p", modifier: [.command, .shift])
        case .openSearchbar:
            Shortcut(key: "t", modifier: .command)
        case .openInlineSearch:
            Shortcut(key: "f", modifier: .command)
        case .goBack:
            Shortcut(key: "ö", modifier: .command)
        case .goForward:
            Shortcut(key: "ä", modifier: .command)
        case .reload:
            Shortcut(key: "r", modifier: .command)
        case .reloadFromSource:
            Shortcut(key: "r", modifier: [.command, .shift])
        case .previousTab:
            Shortcut(key: "w", modifier: [.command, .shift])
        case .nextTab:
            Shortcut(key: "s", modifier: [.command, .shift])
        case .closeCurrentTab:
            Shortcut(key: "c", modifier: [.command, .option])
        case .showHistory:
            Shortcut(key: "y", modifier: .command)
        case .zoomIn:
            Shortcut(key: "+", modifier: .command)
        case .zoomOut:
            Shortcut(key: "-", modifier: .command)
        case .resetZoom:
            Shortcut(key: "0", modifier: .command)
        case .triggerPasswordsAuth:
            Shortcut(key: "u", modifier: .command)
        case .sidebarOrientation:
            Shortcut(key: "n", modifier: [.command, .shift])
        case .moveSingleFrameToWindow:
            Shortcut(key: "b", modifier: .command)
        case .toggleTranslucentFloatingWindow:
            Shortcut(key: "0", modifier: [.command, .shift])
        }
    }
    
    var keyboardShortcut: KeyboardShortcut {
        KeyboardShortcut(self.shortcut.key, modifiers: self.shortcut.modifier)
    }
    
    var shortcutName: String {
        switch self {
        case .newWindow: "Open New Window"
        case .toggleSidebar: "Toggle Sidebar"
        case .toggleSidebarFixed: "Fix Sidebar"
        case .togglePasswords: "Toggle Password Sidebar"
        case .togglePasswordsFixed: "Fix Password Sidebar"
        case .openSearchbar: "Open Searchbar"
        case .openInlineSearch: "Document Search"
        case .goBack: "Go Back"
        case .goForward: "Go Forward"
        case .reload: "Reload"
        case .reloadFromSource: "Reload from Source"
        case .previousTab: "Previous Tab"
        case .nextTab: "Next Tab"
        case .closeCurrentTab: "Close Current Tab"
        case .showHistory: "Show History"
        case .zoomIn: "Zoom In"
        case .zoomOut: "Zoom Out"
        case .resetZoom: "Reset Zoom"
        case .triggerPasswordsAuth: "Authenticate yourself"
        case .sidebarOrientation: "Move your tabs left or right"
        case .moveSingleFrameToWindow: "Move a single-tab window to a full browser window"
        case .toggleTranslucentFloatingWindow: "Toggle translucent floating mode"
        }
    }
    
    var menuButtonName: String {
        switch self {
        case .newWindow:
            "New Window"
        case .toggleSidebar:
            "Toggle Sidebar"
        case .toggleSidebarFixed:
            "Fix Sidebar"
        case .togglePasswords:
            "Toggle Passwords"
        case .togglePasswordsFixed:
            "Fix Passwords"
        case .openSearchbar:
            "Open Searchbar"
        case .openInlineSearch:
            "Document Search"
        case .goBack:
            "Go Back"
        case .goForward:
            "Go Forward"
        case .reload:
            "Reload"
        case .reloadFromSource:
            "Reload from source"
        case .previousTab:
            "Previous Tab"
        case .nextTab:
            "Next Tab"
        case .closeCurrentTab:
            "Close current Tab"
        case .showHistory:
            "Show History"
        case .zoomIn:
            "Zoom In"
        case .zoomOut:
            "Zoom Out"
        case .resetZoom:
            "Reset Zoom"
        case .triggerPasswordsAuth:
            ""
        case .sidebarOrientation:
            "Toggle Tab Position"
        case .moveSingleFrameToWindow:
            ""
        case .toggleTranslucentFloatingWindow:
            "Toggle Floating"
        }
    }
    
    func execute(appViewModel: AppViewModel, openWindow: OpenWindowAction) -> Bool {
        switch self {
        case .newWindow: createNewWindow(appViewModel, openWindow)
        case .toggleSidebar: toggleSidebar(appViewModel)
        case .toggleSidebarFixed: toggleSidebar(fix: true, appViewModel)
        case .togglePasswords: togglePasswordSidebar(appViewModel)
        case .togglePasswordsFixed: togglePasswordSidebar(fix: true, appViewModel)
        case .openSearchbar: newTab(appViewModel)
        case .openInlineSearch: search(appViewModel)
        case .goBack: navigate(appViewModel)
        case .goForward: navigate(back: false, appViewModel)
        case .reload: reload(appViewModel)
        case .reloadFromSource: reload(fromSource: true, appViewModel)
        case .previousTab: navigateTabs(appViewModel)
        case .nextTab: navigateTabs(back: false, appViewModel)
        case .closeCurrentTab: closeCurrentTab(appViewModel)
        case .showHistory: showHistory(appViewModel)
        case .zoomIn: zoom(appViewModel)
        case .zoomOut: zoom(enlarge: false, appViewModel)
        case .resetZoom: resetZoom(appViewModel)
        case .sidebarOrientation: toggleSidebarOrientation(appViewModel)
        case .moveSingleFrameToWindow, .triggerPasswordsAuth: break
        case .toggleTranslucentFloatingWindow: toggleTranslucentWindow(appViewModel)
        }
        switch self {
        case .triggerPasswordsAuth, .moveSingleFrameToWindow:
            return true
        default:
            return false
        }
    }
    
    func contentViewModelForActiveWindow(appViewModel: AppViewModel) -> ContentViewModel? {
        return appViewModel.displayedWindows[appViewModel.currentlyActiveWindowId]
    }
}
