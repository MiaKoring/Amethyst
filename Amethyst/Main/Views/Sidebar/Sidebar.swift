//
//  Untitled.swift
//  Amethyst
//
//  Created by Mia Koring on 28.11.24.
//
import SwiftUI

struct Sidebar: View {
    @Environment(AppViewModel.self) var appViewModel
    @Environment(ContentViewModel.self) var contentViewModel
    @Environment(\.colorScheme) var appearance
    var body: some View {
        ZStack {
            VStack {
                contentViewModel.sidebarOrientation.tabTopRow()
                    .if(!appViewModel.useMacOS26Design) { view in
                        view
                            .addTopRowPadding(isFixed: contentViewModel.isSidebarFixed)
                    }
                    .if(appViewModel.useMacOS26Design) { view in
                        view
                            .padding(.bottom, -10)
                    }
                URLDisplay()
                    .padding(.top)
                    .padding(.horizontal, 3)
                ClearDivider()
                NewTabButton()
                .padding(.horizontal, 3)
                ATabView()
                    .padding(-15)
                    .padding(.horizontal, 3)
                    .safeAreaInset(edge: .bottom) {
                        DownloadOverview()
                    }
            }
            if(!AppViewModel.isDefaultBrowser()) {
                VStack {
                    Spacer()
                    SetDefaultBrowserButton()
                }
            }
            MenuButton()
            .placeBottomLeading()
        }
        .decideSidebarStyling(isFixed: contentViewModel.isSidebarFixed, appearance: appearance, useMacos26Desing: appViewModel.useMacOS26Design)
    }
    
    struct ClearDivider: View {
        @Environment(ContentViewModel.self) var contentViewModel
        @Environment(\.colorScheme) var appearance
        var body: some View {
            HStack {
                VStack { Divider() }
                Button { contentViewModel.tabs = [] } label: {
                    Text("clear")
                        .font(.footnote)
                        .foregroundStyle(appearance == .dark ? Color.gray: Color.gray.mix(with: .black, by: 0.4))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private struct MenuButton: View {
        @State var playAnimation: Bool = false
        @State var isHovered = false
        
        @Environment(AppViewModel.self) var appViewModel
        @Environment(ContentViewModel.self) var contentViewModel
        @Environment(\.openSettings) private var openSettings
        
        var actions: [RadialMenuAction] {
            [
                RadialMenuAction(label: {
                    SidebarBottomButtonLabel(imageName: "bubble.left.and.bubble.right")
                        .help("Feedback")
                }) {
                    let tab = ATab(webViewModel: .init(contentViewModel: contentViewModel, appViewModel: appViewModel))
                    tab.webViewModel.load(urlString: "https://amethyst.featurebase.app")
                    contentViewModel.tabs.append(tab)
                    contentViewModel.currentTab = tab.id
                },
                RadialMenuAction(label: {
                    SidebarBottomButtonLabel(imageName: "gear")
                        .help("Settings")
                }) {
                    openSettings()
                },
                RadialMenuAction(label: {
                    SidebarBottomButtonLabel(imageName: "clock")
                        .help("Search History")
                }) {
                    Keybind.showHistory.showHistory(appViewModel)
                }
            ]
        }
        
        var body: some View {
            RadialMenu(
                actions: actions,
                radius: 60,
                startAngle: -90,
                endAngle: 0
            ) { isExpanded in
                Image(systemName: isExpanded ? "record.circle": "circle.circle")
                    .sizeRef { Image(systemName: "arrow.down.app").font(.title) }
                    .font(.title)
                    .foregroundStyle(.gray.mix(with: .mainColorMix, by: 0.3))
                    .symbolEffect(.bounce, value: playAnimation)
                    .padding(5)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                    .padding(-2)
                    .onHover { isHovered in
                        if isHovered {
                            playAnimation.toggle()
                        }
                        self.isHovered = isHovered
                    }
                    .help("Feedback, Settings and more")
            }
        }
    }
    
    private struct NewTabButton: View {
        @Environment(ContentViewModel.self) var contentViewModel
        @State var isNewTabHovered: Bool = false
        @Environment(\.colorScheme) var appearance
        
        var body: some View {
            Button { contentViewModel.triggerNewTab.toggle() } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("New Tab")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            true: .mainColorMix.opacity(0.1),
                            false: .black.opacity(appearance == .dark ? 0.1: 0.05),
                            with: isNewTabHovered
                        )
                }
            }
            .buttonStyle(.plain)
            .onHover { hovering in isNewTabHovered = hovering }
        }
    }
    
    private struct SetDefaultBrowserButton: View {
        var body: some View {
            Button("Set Default") {
                Task {
                    do {
                        try await NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpenURLsWithScheme: "http")
                    } catch {
                        print(error)
                    }
                }
            }
            .buttonStyle(.borderless)
            .padding(.bottom, 10)
        }
    }
    
    private struct DownloadOverview: View {
        @Environment(AppViewModel.self) var appViewModel
        @State var downloadOverviewButtonIsHovered: Bool = false
        @Environment(\.colorScheme) var appearance
        var body: some View {
            VStack(alignment: .trailing){
                if downloadOverviewButtonIsHovered {
                    ShortDownloadOverview()
                        .transition(.move(edge: .bottom))
                        .padding(.bottom, 10)
                        .background {
                            if #available(macOS 26.0, *), appViewModel.useMacOS26Design {
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .blur(radius: 5)
                            } else {
                                Rectangle()
                                    .fill(appearance == .dark ? .myPurple.mix(with: .white, by: 0.1): Color.test)
                            }
                        }
                        .onHover { hovering in downloadOverviewButtonIsHovered = hovering }
                        .padding(.bottom, -6)
                        .ifMacOS26Available(and: appViewModel.useMacOS26Design) { view in
                            view
                                .padding(.horizontal, -5)
                        }
                }
                DownloadOverviewButton(isHovered: $downloadOverviewButtonIsHovered)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
