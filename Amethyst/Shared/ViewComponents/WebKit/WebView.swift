//
//  WebView.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 17.12.24.
//
import SwiftUI

struct WebView: View {
    let tabID: UUID
    @ObservedObject var webViewModel: WebViewModel
    @Environment(ContentViewModel.self) private var contentViewModel
    @Environment(AppViewModel.self) private var appViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            WebViewNS(viewModel: webViewModel)
                .focused($isFocused)
                .if(webViewModel.error != nil) { view in
                    view.allowsHitTesting(false)
                }
            if let error = webViewModel.error {
                ErrorView(error: error)
            }
            AnimationLayer()
        }
        .if(tabID != contentViewModel.currentTab) { view in
            view
                .hidden()
        }
        .environmentObject(webViewModel)
        .opacity(tabID == contentViewModel.currentTab ? 1 : 0)
        .allowsHitTesting(tabID == contentViewModel.currentTab)
        .clipShape(RoundedRectangle(cornerRadius: AmethystApp.windowRound / 2))
        .padding(appViewModel.useMacOS26Design ? 8: 10)
        .onChange(of: contentViewModel.currentTab) { focusIfActive() }
        .onAppear() { focusIfActive() }
    }
    
    private func focusIfActive(){
        isFocused = (contentViewModel.currentTab == tabID)
    }
    
    private struct ErrorView: View {
        let error: Error
        @EnvironmentObject var webViewModel: WebViewModel
        var body: some View {
            VStack {
                HStack {
                    VStack {
                        Text(error.localizedDescription)
                            .foregroundStyle(.black)
                            .padding()
                            .contextMenu {
                                Button("Copy") {
                                    NSPasteboard.general.setString(error.localizedDescription, forType: .string)
                                }
                            }
                        Button {
                            webViewModel.error = nil
                        } label: {
                            Text("Ignore Error for now")
                                .foregroundStyle(.blue)
                        }
                        Button {
                            ErrorIgnoreManager.addIgnoredURLError(error)
                            webViewModel.error = nil
                        } label: {
                            Text("Ignore Error in the future")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        .buttonRepeatBehavior(.disabled)
                        Text("It still will be logged, but won't interrupt you anymore through displaying fullscreen\nYou can edit ignored Errors in Settings")
                            .font(.footnote)
                            .foregroundStyle(.gray.mix(with: .black, by: 0.2))
                    }
                    Spacer()
                }
                Spacer()
            }
            .background(.white)
        }
    }
    
    private struct AnimationLayer: View {
        var body: some View {
            ZStack {
                LoadingProgress()
                BackgroundTabCreatedInfo()
                DownloadStartedInfo()
            }
            .padding(5)
        }
        
        private struct BackgroundTabCreatedInfo: View {
            @EnvironmentObject private var webViewModel: WebViewModel
            
            var body: some View {
                VStack {
                    if webViewModel.backgroundTabCreatedOverlayTimer?.isValid == true {
                        HStack {
                            Text("Background Tab Created")
                                .font(.title2)
                                .fontWeight(.medium)
                                .padding(10)
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.myPurple.opacity(0.5))
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(lineWidth: 3)
                                                .fill(
                                                    .myPurple
                                                        .mix(with: .white, by: 0.15)
                                                        .opacity(0.4)
                                                )
                                        }
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .animation(.easeIn(duration: 0.3), value: webViewModel.backgroundTabCreatedOverlayTimer?.isValid)
            }
        }
        
        private struct DownloadStartedInfo: View {
            @EnvironmentObject private var webViewModel: WebViewModel
            @Environment(AppViewModel.self) var appViewModel: AppViewModel
            
            var body: some View {
                VStack {
                    Spacer()
                    if webViewModel.downloadCreatedTimer?.isValid == true {
                        HStack {
                            Spacer()
                            appViewModel.standardFileImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50)
                                .shadow(radius: 5)
                                .overlay {
                                    Image(systemName: "arrow.down.app")
                                        .resizable()
                                        .symbolEffect(.wiggle, isActive: true)
                                        .foregroundStyle(.myPurple)
                                        .scaledToFit()
                                        .frame(width: 20)
                                    
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
                .animation(.easeIn(duration: 0.3), value: webViewModel.downloadCreatedTimer?.isValid)
            }
        }
        
        private struct LoadingProgress: View {
            @EnvironmentObject private var webViewModel: WebViewModel
            @Environment(\.colorScheme) private var colorScheme
            var body: some View {
                VStack {
                    if webViewModel.isLoading {
                        ProgressView(value: webViewModel.loadingProgress)
                            .tint(.myPurple)
                            .colorScheme(colorScheme == .dark ? .light: .dark)
                            .progressViewStyle(.linear)
                            .padding(.horizontal, 2.5)
                            .background {
                                Capsule()
                                    .fill(Color.myPurple)
                            }
                            .scaledToFill()
                            .frame(width: 225, height: 14, alignment: .center)
                            .clipShape(Capsule())
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        
                    }
                    Spacer()
                }
                .animation(.easeIn(duration: 0.3), value: webViewModel.isLoading)
            }
        }
    }
}
