//
//  ContentView.swift
//  Browser
//
//  Created by Mia Koring on 27.11.24.
//
import Combine
import SwiftData
import SwiftUI
import WebKit


extension ContentView: View, TabOpener {
    var body: some View {
        @Bindable var appViewModel = appViewModel
        GeometryReader { reader in
            BackgroundView {
                HostingWindowFinder(callback: { window in
                    if let window, let id = window.identifier {
                        self.appViewModel.currentlyActiveWindowId = id.rawValue
                        self.contentViewModel.window = window
                    }
                })
                WindowHighlighter()
                MacosButtonHoverArea(showMacosWindowIconsAreaHovered: $showMacosWindowIconsAreaHovered)
                HStack(spacing: appViewModel.useMacOS26Design ? -9: 0) {
                    FixedSidebar(edge: .leading)
                    ZStack {
                        ForEach(contentViewModel.tabs, id: \.self) { tab in
                            WebView(tabID: tab.id, webViewModel: tab.webViewModel)
                        }
                        InlineSearch()
                    }
                    FixedSidebar(edge: .trailing)
                }
                FloatingSidebars()
                if (showMacosWindowIconsAreaHovered || macosWindowIconsHovered) && !contentViewModel.sidebarOrientation.isLeadingSidebarShown(contentViewModel: contentViewModel) {
                    MacOSWindowButtonsOverlay(macosWindowIconsHovered: $macosWindowIconsHovered)
                }
            }
            .sheet(isPresented: $showInputBar) {
                InputBar(text: $inputBarText, showInputBar: $showInputBar) { text in
                    handleInputBarSubmit(text: text)
                    inputBarText = ""
                    showInputBar = false
                }
                .frame(maxWidth: max(550, min(reader.size.width / 2, 800)))
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                if showHistory {
                    HistoryOverlay(
                        isPresented: $showHistory,
                        modalSize: $historyModalSize,
                        containerSize: reader.size
                    )
                }
            }
            .onAppear(perform: onAppear)
            .onDisappear {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSWindow.didBecomeMainNotification,
                    object: nil
                )
            }
            .onChange(of: contentViewModel.triggerNewTab) { showInputBar = true }
            .onChange(of: contentViewModel.tabs) { if contentViewModel.tabs.isEmpty { contentViewModel.isSidebarShown = true } }
            .onChange(of: contentViewModel.currentTab) { if contentViewModel.currentTab != nil { contentViewModel.isLoaded = true } }
            .onChange(of: contentViewModel.showHistory) { showHistory = contentViewModel.showHistory }
            .onChange(of: showHistory) { contentViewModel.showHistory = showHistory }
            .sheet(isPresented: $appViewModel.showsSetup) { appViewModel.showsSetup = false } content: {
                Setup()
                    .frame(width: 700, height: 400)
                    .interactiveDismissDisabled()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { newValue in
            guard let window = newValue.object as? NSWindow, let id = window.identifier?.rawValue, id == contentViewModel.id else { return }
            appViewModel.displayedWindows[id] = nil
        }
    }

    private struct MacOSWindowButtonsOverlay: View {
        @Binding var macosWindowIconsHovered: Bool
        var body: some View {
            VStack {
                HStack {
                    MacOSButtons()
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.regularMaterial)
                                .background(Color.myPurple.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: AmethystApp.windowRound))
                        }
                        .onHover { hovering in
                            macosWindowIconsHovered = hovering
                        }
                    Spacer()
                }
                Spacer()
            }
        }
    }

    private struct HistoryOverlay: View {
        @Binding var isPresented: Bool
        @Binding var modalSize: CGSize
        let containerSize: CGSize

        private let minWidth: CGFloat = 400
        private let minHeight: CGFloat = 500
        @State private var resizeStartSize: CGSize?

        var body: some View {
            ZStack {
                Color.black.opacity(0.18)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPresented = false
                    }

                HistoryView()
                    .frame(width: clampedWidth, height: clampedHeight)
                    .background {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.25), radius: 25, y: 12)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .contentShape(Rectangle())
                            .gesture(resizeGesture)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .contentShape(RoundedRectangle(cornerRadius: 22))
                    .onTapGesture {
                        // Keep taps inside the modal from dismissing the overlay.
                    }
                    .onKeyPress(.escape) {
                        isPresented = false
                        return .handled
                    }
            }
            .transition(.opacity.animation(.linear(duration: 0.12)))
        }

        private var clampedWidth: CGFloat {
            clamp(modalSize.width, min: minWidth, max: max(minWidth, containerSize.width - 80))
        }

        private var clampedHeight: CGFloat {
            clamp(modalSize.height, min: minHeight, max: max(minHeight, containerSize.height - 80))
        }

        private var resizeGesture: some Gesture {
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let startSize = resizeStartSize ?? modalSize
                    if resizeStartSize == nil {
                        resizeStartSize = modalSize
                    }

                    let newWidth = clamp(
                        startSize.width + value.translation.width * 2,
                        min: minWidth,
                        max: max(minWidth, containerSize.width - 80)
                    )
                    let newHeight = clamp(
                        startSize.height + value.translation.height * 2,
                        min: minHeight,
                        max: max(minHeight, containerSize.height - 80)
                    )

                    modalSize = CGSize(
                        width: newWidth,
                        height: newHeight
                    )
                }
                .onEnded { _ in
                    resizeStartSize = nil
                }
        }

        private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
            Swift.min(Swift.max(value, minValue), maxValue)
        }
    }

    private struct FixedSidebar: View {
        @Environment(ContentViewModel.self) private var contentViewModel
        @State private var width: CGFloat
        let edge: HorizontalEdge

        init(edge: HorizontalEdge) {
            self.edge = edge
            let storedWidth = edge == .trailing ? UDKey.trailingFixedSidebarWidth.doubleValue: UDKey.leadingFixedSidebarWidth.doubleValue
            self.width = storedWidth > 0.0 ? storedWidth: 270
        }

        private var isVisible: Bool {
            switch edge {
            case .leading:
                return contentViewModel.sidebarOrientation.isLeadingSidebarFixed(
                    contentViewModel: contentViewModel
                )
            case .trailing:
                return contentViewModel.sidebarOrientation.isTrailingSidebarFixed(
                    contentViewModel: contentViewModel
                )
            }
        }

        // Provides the correct sidebar content view based on the edge.
        @ViewBuilder
        private var sidebarContent: some View {
            switch edge {
            case .leading:
                contentViewModel.sidebarOrientation.leadingSidebar()
            case .trailing:
                contentViewModel.sidebarOrientation.trailingSidebar()
            }
        }

        // Determines the alignment for the resizer overlay.
        private var resizerAlignment: Alignment {
            switch edge {
            case .leading:
                .trailing
            case .trailing:
                .leading
            }
        }


        var body: some View {
            // Only render the view if the sidebar should be fixed/visible.
            if isVisible {
                HStack(spacing: 0) {
                    // If it's a trailing sidebar and there are no tabs,
                    // add a spacer to push it to the right.
                    if edge == .trailing && contentViewModel.tabs.isEmpty {
                        Spacer()
                    }

                    // The main sidebar content.
                    sidebarContent
                        .frame(maxWidth: width)
                        .overlay(alignment: resizerAlignment) {
                            SidebarResizer(
                                sidebarWidth: $width,
                                trailing: edge == .trailing
                            )
                        }

                    // If it's a leading sidebar and there are no tabs,
                    // add a spacer to push the main content away.
                    if edge == .leading && contentViewModel.tabs.isEmpty {
                        Spacer()
                    }
                }
            }
        }
    }

    private struct FloatingSidebars: View {
        @Environment(ContentViewModel.self) var contentViewModel
        var body: some View {
            HStack {
                if contentViewModel.sidebarOrientation.isLeadingSidebarShown(contentViewModel: contentViewModel) {
                    contentViewModel.sidebarOrientation.leadingSidebar()
                        .transition(.move(edge: .leading))
                }
                Spacer()
                if contentViewModel.sidebarOrientation.isTrailingSidebarShown(contentViewModel: contentViewModel) {
                    contentViewModel.sidebarOrientation.trailingSidebar()
                        .transition(.move(edge: .trailing))
                }
            }
        }

    }

    private struct InlineSearch: View {
        @Environment(ContentViewModel.self) var contentViewModel
        var body: some View {
            if contentViewModel.showInlineSearch, let tab = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab}) {
                VStack {
                    HStack {
                        Spacer()
                        DocumentSearchView(webViewModel: tab.webViewModel, text: contentViewModel.lastInlineQuery)
                            .environmentObject(contentViewModel)
                            .frame(maxWidth: 270)
                            .padding(30)
                    }
                    Spacer()
                }
            }
        }
    }

    private struct WindowHighlighter: View {
        @Environment(AppViewModel.self) var appViewModel
        @Environment(ContentViewModel.self) var contentViewModel
        var cornerRadius: CGFloat {
            if #available(macOS 26.0, *) {
                return 16.5
            } else {
                return 10
            }
        }
        var body: some View {
            if appViewModel.highlightedWindow == contentViewModel.id {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(lineWidth: 5)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private struct MacosButtonHoverArea: View {
        @Binding var showMacosWindowIconsAreaHovered: Bool
        var body: some View {
            VStack {
                HStack {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            showMacosWindowIconsAreaHovered = hovering
                        }
                    Spacer()
                }
                Spacer()
            }
        }
    }

}
