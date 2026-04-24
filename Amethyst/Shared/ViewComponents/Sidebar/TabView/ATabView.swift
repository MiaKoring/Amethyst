
import SwiftUI

struct ATabView: View {
    @Environment(ContentViewModel.self) var contentViewModel
    @Environment(AppViewModel.self) var appViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(contentViewModel.tabs) { tab in
                    TabButton(id: tab.id, tabVM: tab.webViewModel)
                        .transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.3), value: contentViewModel.tabs)
            }
            .padding(15)
        }
        .scrollContentBackground(.hidden)
        .frame(maxHeight: .infinity)
    }
    
    private struct TabButton: View {
        let id: UUID
        @ObservedObject var tabVM: WebViewModel
        @Environment(AppViewModel.self) var appViewModel
        @State var isHovered: Bool = false
        @Environment(ContentViewModel.self) var contentViewModel
        var body: some View {
            TitleDisplay(tabVM: tabVM)
                .padding(10)
                .overlay {
                    HStack(spacing: 0) {
                        Spacer()
                        MediaUsageIndicators(tabVM: tabVM)
                            .padding(.trailing, 5)
                        if isHovered {
                            TabCloseButton(id: id)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background() {
                    ButtonBackground(id: id, isHovered: isHovered)
                }
                .onHover { hovering in
                    isHovered = hovering
                }
                .onTapGesture {
                    contentViewModel.changeToTab(id: id)
                }
        }
        
        private struct MediaUsageIndicators: View {
            @ObservedObject var tabVM: WebViewModel
            var body: some View {
                HStack {
                    if tabVM.isUsingCamera == .active {
                        Image(systemName: "camera.circle.fill")
                            .padding(5)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                            }
                    }
                    if tabVM.isUsingCamera == .muted {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill")
                            .padding(5)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                            }
                    }
                    if tabVM.isUsingMicrophone == .active {
                        Image(systemName: "microphone.circle.fill")
                            .padding(5)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                            }
                    }
                    if tabVM.isUsingMicrophone == .muted {
                        Image(systemName: "microphone.slash.circle.fill")
                            .padding(5)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                            }
                    }
                }
                .font(.title2)
                .foregroundStyle(.gray)
            }
        }
        private struct TabCloseButton: View {
            @Environment(ContentViewModel.self) var contentViewModel
            let id: UUID
            var body: some View {
                Button {
                    withAnimation(.linear(duration: 0.2)) {
                        contentViewModel.closeTab(id: id)
                    }
                } label: {
                    Image(systemName: "xmark.square.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
                .padding(5)
            }
        }
        private struct TitleDisplay: View {
            @ObservedObject var tabVM: WebViewModel
            var body: some View {
                HStack {
                    if let title = tabVM.title, !title.isEmpty {
                        Text(title)
                            .lineLimit(1)
                    } else {
                        Text(tabVM.currentURL?.absoluteString ?? "failed")
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
        }
        
        private struct ButtonBackground: View {
            @Environment(ContentViewModel.self) var contentViewModel
            @Environment(\.colorScheme) var appearance
            let id: UUID
            let isHovered: Bool
            var body: some View {
                ZStack {
                    if contentViewModel.currentTab == id {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(appearance == .dark ? .mainColorMix.opacity(0.2): .white)
                            .shadow(radius: appearance == .dark ? 0: 2)
                    } else {
                        if isHovered {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(appearance == .dark ? .mainColorMix.opacity(0.1): .mainColorMix.opacity(0.02))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(true: .thinMaterial, false: .thinMaterial, with: appearance == .dark)
                        }
                    }
                }
            }
        }
    }

}
