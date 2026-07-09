//
//  HistoryListView.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 04.12.24.
//

import SwiftUI


struct HistoryListView: View {
    @Environment(ContentViewModel.self) private var contentViewModel
    @Environment(AppViewModel.self) var appViewModel
    let items: [HistoryItem]
    let proxy: ScrollViewProxy
    @FocusState var focusedItem: Int?
    @State var shiftPressed: Bool = false
    
    var body: some View {
        LazyVStack {
            ForEach(items, id: \.id) { item in
                HistoryRow(item: item, focusedItem: $focusedItem, shiftPressed: $shiftPressed)
            }
        }
        .onChange(of: focusedItem, focusedItemChanged)
        .onKeyPress(phases: [.down, .up], action: keyPressed)
    }
    
    private func keyPressed(_ event: KeyPress) -> KeyPress.Result {
        if event.modifiers == .shift {
            shiftPressed = event.phase == .down
            return .ignored
        }
        return .ignored
    }
    
    private func focusedItemChanged() {
        if let focusedItem {
            withAnimation(.linear) {
                proxy.scrollTo(focusedItem, anchor: .center)
            }
        }
    }
    
    struct HistoryRow: View {
        let item: HistoryItem
        var focusedItem: FocusState<Int?>.Binding
        @Environment(AppViewModel.self) var appViewModel
        @Environment(ContentViewModel.self) var contentViewModel
        @Environment(\.dismiss) var dismiss
        @Binding var shiftPressed: Bool
        
        var body: some View {
            Button {
                openItem(item)
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(topText())
                            .font(.title2)
                            .lineLimit(1)
                        Text(item.url?.absoluteString ?? "")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(10)
                .background() {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.ultraThinMaterial)
                }
            }
            .buttonStyle(.plain)
            .focused(focusedItem, equals: item.id)
        }
        
        func topText() -> String {
            guard let title = item.title, !title.isEmpty else {
                return item.url?.host() ?? item.url?.absoluteString ?? ""
            }
            return title
        }
        
        func openItem(_ item: HistoryItem) {
            guard let url = item.url else { return }
            let id = UUID()
            let vm = WebViewModel(contentViewModel: contentViewModel, appViewModel: appViewModel, id: id)
            vm.load(urlString: url.absoluteString)
            let tab = ATab(id: id, webViewModel: vm)
            contentViewModel.tabs.append(tab)
            if !shiftPressed {
                contentViewModel.currentTab = tab.id
                dismiss()
            }
        }
    }
    
}
