//
//  KeybindsGroup.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 13.12.24.
//
import SwiftUI
@MainActor
enum KeybindsGroup: String, CaseIterable {
    case window = "Window"
    case sidebars = "Sidebars"
    case search = "Search"
    case navigation = "Navigation"
    case archive = "Archive"
    case view = "View"
}

extension KeybindsGroup {
    var children: [Keybind] {
        switch self {
        case .window:
            [.newWindow, .toggleTranslucentFloatingWindow]
        case .sidebars:
            [.toggleSidebar, .toggleSidebarFixed, .togglePasswords, .togglePasswordsFixed, .triggerPasswordsAuth]
        case .search:
            [.openSearchbar, .openInlineSearch]
        case .view:
            [.zoomIn, .zoomOut, .resetZoom, .sidebarOrientation, .moveSingleFrameToWindow]
        case .navigation:
            [.goBack, .goForward, .reload, .reloadFromSource, .previousTab, .nextTab, .closeCurrentTab]
        case .archive:
            [.showHistory]
        }
    }
    
    @CommandsBuilder
    func commandGroup(appViewModel: AppViewModel, openWindow: OpenWindowAction) -> some Commands {
        switch self {
        case .window:
            CommandGroup(replacing: .newItem) {
                self.commands(appViewModel: appViewModel, openWindow: openWindow)
            }
        case .sidebars:
            CommandGroup(after: .sidebar) {
                self.commands(appViewModel: appViewModel, openWindow: openWindow)
            }
        case .search:
            CommandMenu("Find") {
                self.commands(appViewModel: appViewModel, openWindow: openWindow)
            }
        case .navigation:
            CommandMenu("Navigation") {
                self.commands(appViewModel: appViewModel, openWindow: openWindow)
            }
        case .archive:
            CommandMenu("Archive") {
                self.commands(appViewModel: appViewModel, openWindow: openWindow)
            }
        case .view:
            CommandMenu("View") {
                self.commands(appViewModel: appViewModel, openWindow: openWindow)
            }
        }
    }
    
    @ViewBuilder func commands(appViewModel: AppViewModel, openWindow: OpenWindowAction) -> some View {
        ForEach(self.children, id: \.hashValue) { child in
            Button(child.menuButtonName) {
                _ = child.execute(appViewModel: appViewModel, openWindow: openWindow)
            }
            .keyboardShortcut(child.keyboardShortcut)
            .disabled(appViewModel.showsSetup)
        }
    }
}

