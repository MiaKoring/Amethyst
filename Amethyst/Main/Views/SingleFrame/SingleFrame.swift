//
//  SingleFrame.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 30.11.24.
//

import SwiftUI
import WebKit

struct SingleFrame: View {
    @Environment(AppViewModel.self) var appViewModel
    @StateObject var webViewModel: MiniWebViewModel
    @Binding var url: URL?
    @State var showWindowSelection: Bool = false
    
    init(appViewModel: AppViewModel, url: Binding<URL?>) {
        //webViewModel.load(urlString: url.wrappedValue?.absoluteString ?? (SearchEngine(rawValue: UDKey.searchEngine.intValue) ?? .duckduckgo).root)
        self._webViewModel = StateObject(wrappedValue: MiniWebViewModel(appViewModel: appViewModel))
        self._url = url
    }
    var body: some View {
        BackgroundView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { showWindowSelection.toggle() } label: {
                        Text("Open in Window")
                            .opacity(0.6)
                            .bold()
                            .padding(10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.thinMaterial)
                                    .background(.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                    }
                    .keyboardShortcut(Keybind.moveSingleFrameToWindow.shortcut.key, modifiers: Keybind.moveSingleFrameToWindow.shortcut.modifier)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .focusable(false)
                }
                MiniWebView(viewModel: webViewModel)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(10)
            }
        }
        .onChange(of: webViewModel.currentURL) { url = webViewModel.currentURL }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .sheet(isPresented: $showWindowSelection) {
            WindowSelection(showWindowSelection: $showWindowSelection, webViewModel: webViewModel)
        }
        .onAppear {
            let initialURLString = url?.absoluteString ?? (SearchEngine(rawValue: UDKey.searchEngine.intValue) ?? .duckduckgo).root
            webViewModel.load(urlString: initialURLString)
        }
    }
    
    private struct WindowSelection: View {
        @Environment(AppViewModel.self) var appViewModel
        @Environment(\.dismissWindow) var dismissWindow
        @Binding var showWindowSelection: Bool
        let webViewModel: MiniWebViewModel
        
        var body: some View {
            ZStack {
                HStack {
                    ForEach(appViewModel.displayedWindows.keys.sorted(), id: \.self) { window in
                        Button {
                            handleWindowOpening(selected: window)
                        } label: {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.myPurple.opacity(0.3))
                                .frame(width: 200, height: 200)
                                .overlay {
                                    Text(window.replacingOccurrences(of: "mainWindow-AppWindow-", with: ""))
                                        .allowsHitTesting(false)
                                }
                                .onHover { hovering in
                                    if hovering {
                                        appViewModel.highlightedWindow = window
                                    } else {
                                        appViewModel.highlightedWindow = ""
                                    }
                                }
                                .contentShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        handleWindowOpening(selected: "newWindow")
                    } label: {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.myPurple.opacity(0.3))
                            .frame(width: 200, height: 200)
                            .overlay {
                                ZStack {
                                    Image(systemName: "plus")
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background() {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.thinMaterial)
                        .background(.myPurple.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        
        func handleWindowOpening(selected: String) {
            guard let open = appViewModel.openMiniInNewTab else { return }
            open(webViewModel.currentURL, selected, true)
            showWindowSelection = false
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                dismissWindow()
            }
        }
    }
}
