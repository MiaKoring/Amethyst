//
//  SettingsView.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 13.12.24.
//

import SwiftUI
import AppKit
import TipKit

struct SettingsView: View {
    @Environment(AppViewModel.self) var appViewModel
    @StateObject private var fileDownloader = SetupStep.DownloadIndexView.FileDownloader()
    
    var body: some View {
        ZStack {
            HostingWindowFinder(callback: { window in
                if let window {
                    if let id = window.identifier {
                        self.appViewModel.currentlyActiveWindowId = id.rawValue
                    }
                }
            })
            TabView {
                Tab {
                    KeyBindsView()
                } label: {
                    Label("Key Bindings", systemImage: "keyboard")
                }
                Tab {
                    ViewOptions()
                } label: {
                    Label("Design", systemImage: "paintbrush.pointed")
                }
                Tab {
                    ProductivitySettings()
                } label: {
                    Label("Productivity", systemImage: "chart.bar")
                }
                Tab {
                    SearchEngineSelectionView()
                } label: {
                    Label("Search Engine", systemImage: "globe")
                }
                Tab {
                    SearchSuggestion()
                        .environmentObject(fileDownloader)
                } label: {
                    Label("Search Suggestions", systemImage: "sparkle.magnifyingglass")
                }
                Tab {
                    SidebarOrientation()
                } label: {
                    Label("SidebarOrientation", systemImage: "sidebar.left")
                }
                Tab {
                    IgnoredErrorsView()
                } label: {
                    Label("Ignored Errors", systemImage: "exclamationmark.octagon")
                }
            }
        }
    }
    
    struct ViewOptions: View {
        @Environment(AppViewModel.self) var appViewModel
        @State var useMacos26upDesign = !UDKey.useOldDesign.boolValue
        @State var translucency: Double = UDKey.tranclucency.doubleValue <= 0 ? 0.4 : UDKey.tranclucency.doubleValue
        
        var body: some View {
            Form {
                Toggle("Use New Design", isOn: $useMacos26upDesign)
                    .toggleStyle(.switch)
                    .onChange(of: useMacos26upDesign) {
                        UDKey.useOldDesign.boolValue = !useMacos26upDesign
                        appViewModel.useMacOS26Design = useMacos26upDesign
                    }
                Slider(value: $translucency, in: 0.1...0.9) {
                    Text("Opacity while floating")
                } minimumValueLabel: {
                    Text("0.1")
                } maximumValueLabel: {
                    Text("0.9")
                } onEditingChanged: { isEditing in
                    if !isEditing {
                        UDKey.tranclucency.doubleValue = translucency
                    }
                }
                
            }
            .formStyle(.grouped)
        }
    }
    
    struct SearchSuggestion: View {
        @State var current: SetupStep = .downloadIndex
        var body: some View {
            BackgroundView(shouldRotate: false) {
                VStack {
                    ZStack {
                        ForEach(SetupStep.allCases) { step in
                            step.view(current: $current)
                                .frame(width: 680, height: 380)
                                .if (step != current) { view in
                                    view.hidden()
                                }
                                .padding(.top, 10)
                        }
                        HStack {
                            if current != .downloadIndex {
                                Button {
                                    current = current.previous
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.title)
                                        .padding(.leading, 5)
                                }
                                .buttonStyle(.borderless)
                            }
                            Spacer()
                            if current != .checkMeiliRunning && current != .welcome {
                                Button {
                                    current = current.next
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.title)
                                        .padding(.trailing, 5)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .frame(height: 450)
                }
                .background() {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.thinMaterial)
                }
                .padding(10)
            }
        }
    }
    
    struct ShortcutEditView: View {
        let manager: ShortcutFeatureManager
        @State var showTemporary = false
        
        var body: some View {
            TipView(manager.tip)
            List {
                HStack {
                    Text("Shortcut")
                        .frame(width: 60, alignment: .leading)
                    Divider()
                    Text("Destination")
                    Spacer()
                    Button {
                        showTemporary = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(showTemporary)
                }
                .foregroundStyle(.secondary)
                if showTemporary {
                    ShortcutRow(manager: manager, shortcut: "", destination: "") {
                        self.showTemporary = false
                    }
                }
                ForEach(manager.registered.keys.sorted()) { key in
                    ShortcutRow(manager: manager, shortcut: key, destination: manager.registered[key]!)
                }
            }
        }
        struct ShortcutRow: View {
            let manager: ShortcutFeatureManager
            @State var shortcut: String
            @State var destination: String
            let oldShortcut: String
            let oldDestination: String
            let onPersist: (() -> Void)?
            
            init(manager: ShortcutFeatureManager, shortcut: String, destination: String, onPersist: (() -> Void)? = nil) {
                self.manager = manager
                self._shortcut = State(initialValue: shortcut)
                self._destination = State(initialValue: destination)
                self.oldShortcut = shortcut
                self.oldDestination = destination
                self.onPersist = onPersist
            }
            
            var body: some View {
                HStack {
                    TextField("", text: $shortcut)
                        .frame(width: 60)
                    Divider()
                    TextField("", text: $destination)
                    Button("Save") {
                        if shortcut != oldShortcut {
                            manager.remove(key: oldShortcut)
                        }
                        manager.set(destination, for: shortcut)
                        onPersist?()
                    }
                    .disabled(shortcut.isEmpty || destination.isEmpty || (shortcut == oldShortcut && destination == oldDestination))
                    Button {
                        manager.remove(key: oldShortcut)
                        onPersist?()
                    } label: {
                        Image(systemName: "minus")
                    }
                }
            }
        }
    }
    
    struct ProductivitySettings: View {
        @State private var selection = ProductivityView.bangs
        @State var showHelpSheet = false
        
        var body: some View {
            HStack {
                ForEach(ProductivityView.allCases, id: \.rawValue) { feature in
                    feature.button(selection: $selection)
                }
            }
            
            switch selection {
                case .bangs:
                    ShortcutEditView(manager: BangManager.shared)
                case .commands:
                    ShortcutEditView(manager: CommandsManager.shared)
            }
        }
        
        @MainActor
        private enum ProductivityView: String, CaseIterable {
            case bangs = "Bang Queries"
            case commands = "Commands"
            
            @ViewBuilder
            func button(selection: Binding<Self>) -> some View {
                if #available(macOS 26, *) {
                    Button(rawValue) {
                        selection.wrappedValue = self
                    }
                    .if(selection.wrappedValue == self) { view in
                        view.buttonStyle(.glassProminent)
                    }
                } else {
                    Button(rawValue) {
                        selection.wrappedValue = self
                    }
                    .if(selection.wrappedValue == self) { view in
                        view.buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
}

struct CommandsTip: Tip {
    var title: Text {
        Text("Get to websites quickly")
    }
    
    var message: Text? {
        Text("To use a command type ") +
        Text(":shortcut").fontDesign(.monospaced) +
        Text(" in the input bar and press enter. It will take you directly to the set destination.")
    }
}

struct BangTip: Tip {
    var title: Text {
        Text("Quick search various websites")
    }
    
    var message: Text? {
        Text("To use a bang type ") +
        Text("!shortcut <searchterm>").fontDesign(.monospaced) +
        Text(" in the input bar and press enter. It will directly search on the set website.\n") +
        Text("Create a bang by setting a shortcut and adding the destination including the search query parameter. The searchterm will be formatted and appended to the base url. A destination should be formatted like this: ") +
        Text("https://github.com/search?q=").fontDesign(.monospaced)
    }
}
