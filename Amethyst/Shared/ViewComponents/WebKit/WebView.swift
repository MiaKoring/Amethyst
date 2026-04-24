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
    @Environment(ContentViewModel.self) var contentViewModel
    @Environment(AppViewModel.self) var appViewModel
    @FocusState var isFocused: Bool
    
    var body: some View {
        ZStack {
            WebViewNS(viewModel: webViewModel)
                .focused($isFocused)
                .if(webViewModel.error != nil) { view in
                    view.allowsHitTesting(false)
                }
            if let error = webViewModel.error {
                ErrorView(error: error, webViewModel: webViewModel)
            }
        }
        .if(tabID != contentViewModel.currentTab) { view in
            view
                .hidden()
        }
        .opacity(tabID == contentViewModel.currentTab ? 1 : 0)
        .allowsHitTesting(tabID == contentViewModel.currentTab)
        .clipShape(RoundedRectangle(cornerRadius: AmethystApp.windowRound / 2))
        .padding(appViewModel.useMacOS26Design ? 8: 10)
        .onChange(of: contentViewModel.currentTab) {
            if contentViewModel.currentTab == tabID {
                isFocused = true
            }
        }
    }
    
    private struct ErrorView: View {
        let error: Error
        @ObservedObject var webViewModel: WebViewModel
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
}
