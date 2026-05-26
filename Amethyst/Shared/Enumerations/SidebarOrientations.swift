//
//  SidebarOrientations.swift
//  Amethyst Project
//
//  Created by Mia Koring on 04.06.25.
//
import SwiftUI

@MainActor
enum SidebarOrientations: CaseIterable {
    case tabsLeading, tabsTrailing
}

extension SidebarOrientations {
    var image: Image {
        switch self {
        case .tabsLeading:
            Image(.leadingTabs)
        case .tabsTrailing:
            Image(.trailingTabs)
        }
    }
    
    var isTabTrailing: Bool {
        self == .tabsTrailing
    }
    
    func passwordsTopRow(sortData: Binding<PasswordSortData>, prepareCreationSheet: @escaping () -> Void) -> some View {
        return PasswordTopRow(sidebarOrientation: self, sortData: sortData, prepareCreationSheet: prepareCreationSheet)
        
        struct PasswordTopRow: View {
            @Environment(ContentViewModel.self) var contentViewModel
            @Environment(AppViewModel.self) var appViewModel
            @Environment(\.colorScheme) var appearance
            let sidebarOrientation: SidebarOrientations
            @Binding var sortData: PasswordSortData
            @State var isPlusHovered: Bool = false
            var prepareCreationSheet: () -> Void
            @State var isSidebarButtonHovered = false
            
            var body: some View {
                HStack {
                    if sidebarOrientation == .tabsTrailing {
                        MacOSButtons()
                            .padding(.trailing)
                            .padding(.leading, 5)
                    }
                    Image(systemName: sidebarOrientation.passwordSidebarButton)
                        .sidebarTopButton(hovered: $isSidebarButtonHovered, clickAnimated: false, appearance: appearance, useMacos26Design: appViewModel.useMacOS26Design) {
                            contentViewModel.isPasswordFixed.toggle()
                            contentViewModel.isPasswordShown = false
                        }
                    Spacer()
                    if sidebarOrientation == .tabsLeading {
                        Text("Passwords")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    SelectionMenu(sortDirectionAcending: $sortData.ascending, sortFilter: $sortData.filter, triggerSort: $sortData.triggerSort)
                    
                    Image(systemName: "plus")
                        .sidebarTopButton(hovered: $isPlusHovered, clickAnimated: false, appearance: appearance, useMacos26Design: appViewModel.useMacOS26Design) {
                            prepareCreationSheet()
                        }
                }
            }
        }
        
    }
    
    func tabTopRow() -> some View {
        return TabsTopRow(sidebarOrientation: self)
        
        struct TabsTopRow: View {
            @Environment(\.colorScheme) var appearance
            @Environment(ContentViewModel.self) var contentViewModel
            @Environment(AppViewModel.self) var appViewModel
        @State private var isBackHovered = false
            @State private var isForwardHovered = false
            @State private var isReloadHovered = false
            @State private var isSidebarButtonHovered = false
            var sidebarOrientation: SidebarOrientations
            
            var body: some View {
                HStack {
                    if sidebarOrientation == .tabsLeading {
                        MacOSButtons()
                            .padding(.trailing)
                            .padding(.leading, 5)
                    }
                    Image(systemName: sidebarOrientation.tabSidebarButton)
                        .sidebarTopButton(hovered: $isSidebarButtonHovered, clickAnimated: false, appearance: appearance, useMacos26Design: appViewModel.useMacOS26Design) {
                            contentViewModel.isSidebarFixed.toggle()
                            contentViewModel.isSidebarShown = false
                        }
                    Spacer()
                    Image(systemName: "chevron.left")
                        .sidebarTopButton(hovered: $isBackHovered, appearance: appearance, useMacos26Design: appViewModel.useMacOS26Design) {
                            if let tab = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab}) {
                                tab.webViewModel.webView?.goBack()
                            }
                        }
                    Image(systemName: "chevron.right")
                        .sidebarTopButton(hovered: $isForwardHovered,  appearance: appearance, useMacos26Design: appViewModel.useMacOS26Design) {
                            if let tab = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab}) {
                                tab.webViewModel.webView?.goForward()
                            }
                        }
                    Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                        .sidebarTopButton(hovered: $isReloadHovered, appearance: appearance, useMacos26Design: appViewModel.useMacOS26Design) {
                            if let tab = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab}) {
                                tab.webViewModel.webView?.reload()
                            }
                        }
                }
            }
        }
        
    }
    
    var passwordSidebarButton: String {
        switch self {
        case .tabsLeading:
            "sidebar.right"
        case .tabsTrailing:
            "sidebar.left"
        }
    }
    var tabSidebarButton: String {
        switch self {
        case .tabsTrailing:
            "sidebar.right"
        case .tabsLeading:
            "sidebar.left"
        }
    }
    
    @ViewBuilder
    func leadingSidebar() -> some View {
        switch self {
        case .tabsLeading:
            Sidebar()
        case .tabsTrailing:
            PasswordSidebar()
        }
    }
    
    @ViewBuilder
    func trailingSidebar() -> some View {
        switch self {
        case .tabsLeading:
            PasswordSidebar()
        case .tabsTrailing:
            Sidebar()
        }
    }
    
    func isLeadingSidebarFixed(contentViewModel: ContentViewModel) -> Bool {
        switch self {
        case .tabsLeading:
            contentViewModel.isSidebarFixed
        case .tabsTrailing:
            contentViewModel.isPasswordFixed
        }
    }
    func isTrailingSidebarFixed(contentViewModel: ContentViewModel) -> Bool {
        switch self {
        case .tabsTrailing:
            contentViewModel.isSidebarFixed
        case .tabsLeading:
            contentViewModel.isPasswordFixed
        }
    }
    
    func isLeadingSidebarShown(contentViewModel: ContentViewModel) -> Bool {
        switch self {
        case .tabsLeading:
            contentViewModel.isSidebarShown && !contentViewModel.isSidebarFixed
        case .tabsTrailing:
            contentViewModel.isPasswordShown && !contentViewModel.isPasswordFixed
        }
    }
    
    func isTrailingSidebarShown(contentViewModel: ContentViewModel) -> Bool {
        switch self {
        case .tabsTrailing:
            contentViewModel.isSidebarShown && !contentViewModel.isSidebarFixed
        case .tabsLeading:
            contentViewModel.isPasswordShown && !contentViewModel.isPasswordFixed
        }
    }
    
    var other: SidebarOrientations {
        switch self {
        case .tabsLeading:
                .tabsTrailing
        case .tabsTrailing:
                .tabsLeading
        }
    }
}
