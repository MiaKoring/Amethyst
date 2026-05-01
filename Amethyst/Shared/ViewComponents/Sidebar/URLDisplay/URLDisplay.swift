import SwiftUI

extension URLDisplay: View {
    var body: some View {
        VStack {
            if !showTextField {
                HStack {
                    if let currentTab = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab}) {
                        Display(webViewModel: currentTab.webViewModel, url: $url)
                            .allowsHitTesting(false)
                    } else {
                        Text("Search or enter URL")
                            .allowsHitTesting(false)
                    }
                    Spacer()
                }
            } else {
                TextField("Search or URL", text: $text)
                    .focused($urlTextFieldFocused)
                    .textFieldStyle(.plain)
            }
        }
        .padding(10)
        .background() {
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(appearance == .dark ? 0.1: 0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    if !showTextField {
                        text = url
                        showTextField = true
                        urlTextFieldFocused = true
                    }
                }
        }
        .foregroundStyle(.mainColorMix.opacity(0.5))
        .onKeyPress(.escape) {
            showTextField = false
            return .handled
        }
        .onSubmit {
            if let currentTab = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab}) {
                handleInputBarSubmit(text: text, tabID: currentTab.id)
                showTextField = false
            } else {
                handleInputBarSubmit(text: text)
                showTextField = false
            }
        }
        .onChange(of: contentViewModel.currentTab) {
            showTextField = false
        }
    }
    
    struct Display: View {
        @ObservedObject var webViewModel: WebViewModel
        @Binding var url: String
        var body: some View {
            VStack {
                if let currentUrl = webViewModel.currentURL {
                    Text(currentUrl.host() ?? "Loading...")
                        .onAppear {
                            url = currentUrl.absoluteString
                        }
                } else {
                    Text("Loading...")
                }
            }
            .onChange(of: webViewModel.currentURL) {
                if let new = webViewModel.currentURL {
                    url = new.absoluteString
                }
            }
        }
    }
}

