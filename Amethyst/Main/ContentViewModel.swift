//
//  ContentViewModel.swift
//  Browser
//
//  Created by Mia Koring on 27.11.24.
//
import SwiftUI
import SwiftData
import WebKit
import AuthenticationServices
import OSLog

@Observable
class ContentViewModel: NSObject, ObservableObject, Identifiable {
    var id: String
    var creationDate = Date()
    var triggerNewTab: Bool = false
    var isSidebarShown: Bool = false
    var isSidebarFixed: Bool = false
    var isPasswordShown: Bool = false
    var isPasswordFixed: Bool = false
    var currentTab: UUID?
    var tabs: [ATab] = []
    var blockNotification: Bool = false
    var showInlineSearch: Bool = false
    var showHistory: Bool = false
    var lastInlineQuery: String = ""
    var isLoaded: Bool = false
    var sidebarOrientation: SidebarOrientations
    var showSetup: Bool = false

    var window: NSWindow? = nil

    var onClose: (() -> Void)?

    init(id: String) {
        self.id = id
        self.sidebarOrientation = UDKey.sidebarOrientation.boolValue ? .tabsTrailing: .tabsLeading
    }

    func handleClose() {
        guard let index = tabs.firstIndex(where: {$0.id == currentTab}) else { return }
        if tabs.count > 1 {
            let before = tabs[max(0, index - 1)].id
            let after = tabs[min(tabs.count - 1, index + 1)].id
            currentTab = before == currentTab ? after : before
        } else {
            currentTab = nil
        }
    }


    func tabFor(id: UUID?) -> ATab? {
        return tabs.first(where: {$0.id == id})
    }

    func closeTab(id: UUID) {
        Task {
            await tabs.first(where: {$0.id == id})?.webViewModel.cleanup()
            if currentTab == id {
                handleClose()
            }
            tabs.removeAll(where: {$0.id == id})
        }
    }

    func changeToTab(id: UUID) {
        if let currentTab = tabs.first(where: {$0.id == currentTab}) {
            currentTab.webViewModel.removeHighlights()
        }
        showInlineSearch = false
        currentTab = id
    }
}

struct ContentView {
    static let logger = Logger(subsystem: AmethystApp.subSystem, category: "ContentViewModel")

    @Environment(AppViewModel.self) var appViewModel: AppViewModel
    @Environment(ContentViewModel.self) var contentViewModel: ContentViewModel
    @Environment(\.dismissWindow) var dismissWindow
    @State var showInputBar: Bool = false
    @State var inputBarText: String = ""
    @State var showMacosWindowIconsAreaHovered: Bool = false
    @State var macosWindowIconsHovered: Bool = false
    @Environment(\.scenePhase) var scenePhase
    @State var showHistory = false
    @State var historyModalSize = CGSize(width: 400, height: 500)

    func onAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = contentViewModel.window, let id = window.identifier?.rawValue {
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                window.delegate = appViewModel
                appViewModel.displayedWindows[id] = contentViewModel
                contentViewModel.id = id
            }
        }
        #if DEBUG
        CDTabController.shared.printKnownEntities()
        #endif
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: .main
        ) { notification in
            if contentViewModel.blockNotification { // to block reinserting the window on close
                contentViewModel.blockNotification = false
                return
            }
        }

        if let newURL = appViewModel.newURLToOpen {
            appViewModel.newURLToOpen = nil

            let vm = WebViewModel(contentViewModel: contentViewModel, appViewModel: appViewModel)
            vm.load(url: newURL)
            let newTab = ATab(webViewModel: vm)

            contentViewModel.tabs.append(newTab)
            contentViewModel.currentTab = newTab.id
        }
        if contentViewModel.tabs.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let savedTabs = CDTabController.fetchAllFor(windowID: contentViewModel.id)

                var memoizedIDs = [UUID]()
                for savedTab in savedTabs {
                    guard let id = savedTab.tabID, !memoizedIDs.contains(id) else {
                        continue
                    }
                    memoizedIDs.append(id)
                    let vm = WebViewModel(contentViewModel: contentViewModel, appViewModel: appViewModel)
                    vm.load(urlString: savedTab.url?.absoluteString ?? "about:blank")
                    let newTab = ATab(id: id, webViewModel: vm)
                    contentViewModel.tabs.append(newTab)
                }
                CDTabController.deleteFor(windowID: contentViewModel.id)
                contentViewModel.isSidebarFixed = true
            }
        }
    }

}
