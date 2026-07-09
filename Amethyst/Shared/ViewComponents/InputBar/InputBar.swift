//
//  InputBarViewModel.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 03.12.24.
//
import SwiftUI
import OSLog

struct InputBar: View {
    @Environment(AppViewModel.self) var appViewModel
    @Environment(\.colorScheme) var appearance
    @Binding var text: String
    @Binding var showInputBar: Bool
    @State var timer: Timer? = nil
    @State var quickSearchResults: [SearchSuggestion] = []
    @State var selectedResult: Int = 0
    let onSubmit: (String) -> Void
    
    static var logger = Logger(subsystem: AmethystApp.subSystem, category: "InputBar")
    
    static let suggestionItemMaxCount = 5
    
    var body: some View {
        VStack {
            InputField(text: $text, selectedResult: $selectedResult, quickSearchResults: $quickSearchResults, showInputBar: $showInputBar, onSubmit: onSubmit) { up in
                updateSelection(up: up)
            }
            ForEach(quickSearchResults, id: \.id) { result in
                SuggestionItem(result: result, onSubmit: onSubmit, highlighted: getSuggestionIndex(id: result.id) == selectedResult)
            }
        }
        .padding(10)
        .background() {
            RoundedRectangle(cornerRadius: 10)
                .fill(.myPurple.opacity(0.5))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 2)
                        .foregroundStyle(.myPurple.mix(with: .white, by: 0.15).opacity(0.4))
                }
        }
        .onChange(of: text, updateSuggestionDebounce)
    }
    
    private func updateSuggestionDebounce() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            Task { @MainActor in
                if text.count >= 2 {
                    await timerSuggestionFetch()
                }
            }
        }
    }
    
    private func getSuggestionIndex(id: UUID) -> Int {
        (quickSearchResults.firstIndex(where: { $0.id == id }) ?? -1) + 1
    }
    
    private struct InputField: View {
        @Binding var text: String
        @FocusState var inputFocused: Bool
        @Binding var selectedResult: Int
        @Binding var quickSearchResults: [SearchSuggestion]
        @Binding var showInputBar: Bool
        let onSubmit: (String) -> Void
        let updateSelection: (Bool) -> Void
        
        var textFieldBackgroundFill: Color {
            if selectedResult == 0 { return .myPurple.mix(with: .mainColorMix, by: 0.1)}
            return .myPurple.mix(with: .mainColorMix, by: 0.07)
        }
        
        var body: some View {
            TextField("Search or enter URL", text: $text)
                .textFieldStyle(.plain)
                .font(.title)
                .focused($inputFocused)
                .padding()
                .background() {
                    if #available(macOS 26.0, *) {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(textFieldBackgroundFill.opacity(0.3))
                    } else {
                        RoundedRectangle(cornerRadius: 5)
                                .fill(textFieldBackgroundFill.opacity(0.3))
                    }
                }
                .onSubmit(submitTriggered)
                .onKeyPress(.escape) {
                    showInputBar = false
                    return .handled
                }
                .onKeyPress(action: handleSelectionChangeEvent)
                .onAppear() { inputFocused = true }
        }
        
        private func submitTriggered() {
            let result = selectedResult
            let searchResults = quickSearchResults
            guard result != 0, let suggestion = searchResults[result - 1, default: nil] else {
                onSubmit(text)
                return
            }
            onSubmit(suggestion.urlString)
        }
        
        private func handleSelectionChangeEvent(_ event: KeyPress) -> KeyPress.Result {
            if event.key == .tab && event.modifiers.isEmpty {
                updateSelection(false)
                return .handled
            }
            if event.key == KeyEquivalent("\u{19}") && event.modifiers == .shift {
                updateSelection(true)
                return .handled
            }
            return .ignored
        }
    }
    
    private struct SuggestionItem: View {
        let result: SearchSuggestion
        let onSubmit: (String) -> Void
        let highlighted: Bool
        
        var body: some View {
            HStack {
                result.origin.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                Text(result.title)
                    .font(.title3)
                    .padding(5)
                    .lineLimit(1, reservesSpace: true)
                Text(result.urlString)
                    .font(.title3)
                    .padding(5)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                Spacer()
            }
            .padding(10)
            .background {
                if highlighted {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(lineWidth: 2)
                        .foregroundStyle(.myPurple.mix(with: .mainColorMix, by: 0.15).opacity(0.6))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onSubmit(result.urlString) }
        }
    }
}
