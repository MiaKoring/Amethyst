//  MeiliSetupStep.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 06.12.24.
//


import SwiftUI
import CryptoKit
@preconcurrency import MeiliSearch
import OSLog
import Synchronization

@MainActor
enum SetupStep: Int, CaseIterable {
    case welcome
    case searchEngine
    case sidebarOrientation
    case shortcuts
    case downloadIndex
    case setupAutostart
    case checkMeiliRunning
}

extension SetupStep: @MainActor Identifiable {
    var id: Int {
        self.rawValue
    }
    
    var next: SetupStep {
        SetupStep(rawValue: self.rawValue + 1) ?? .checkMeiliRunning
    }
     
    var previous: SetupStep {
        SetupStep(rawValue: self.rawValue - 1) ?? .welcome
    }
}

extension SetupStep {
    @ViewBuilder
    func view(current: Binding<SetupStep>) -> some View {
        switch self {
        case .welcome:
            WelcomeScreen(current: current)
        case .searchEngine:
            VStack {
                Text("Choose your websearch engine")
                    .font(.title)
                    .padding(.bottom, 15)
                SearchEngineSelectionView(maxHeight: 55)
            }
        case .sidebarOrientation:
            SidebarOrientation()
        case .shortcuts:
            ShortcutsInfoScreen()
        case .downloadIndex:
            DownloadIndexView()
        case .setupAutostart:
            SetupAutostart()
        case .checkMeiliRunning:
            CheckMeiliRunning()
        }
        
    }
    
    private struct ShortcutsInfoScreen: View {
        @Environment(\.openWindow) var openWindow
        var body: some View {
            VStack {
                Text("Amethyst Browser is largely designed for keyboard use.")
                    .font(.title)
                Text("To learn and customize Shortcuts open the Key Bindings tab in the Amethyst Browser Settings.")
                    .font(.title3)
                Image(.keyboardShortcutSettings)
                    .resizable()
                    .scaledToFit()
            }
            .padding()
        }
    }
    
    private struct SetupAutostart: View {
        var body: some View {
            VStack {
                Text("Setup Login Item")
                    .font(.title)
                Image("LoginItems")
                    .resizable()
                    .scaledToFit()
                    .shadow(color: .myPurple, radius: 10)
                    .padding(.horizontal, 30)
                Text("Congratulations! You're almost there! The last step ist to configure Amethyst Index to open at login. For that click on \"Open Login-Items\". That Button will bring you directly in the Settings to the Login Items. There just click on the plus, like marked in the image above and add Amethyst Index!")
                    .padding(.horizontal, 30)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("Open Login-Items")
                }
                .buttonStyle(.borderless)
                .padding(.bottom, 10)
            }
        }
    }
    
    struct DownloadIndexView: View {
        @EnvironmentObject private var downloader: FileDownloader
        var body: some View {
            VStack {
                Text("Download Amethyst Index")
                    .font(.title)
                VStack {
                    if downloader.state.withLock({ state in state }) == .idle {
                        Text("For local search suggestions we need a small helper app called Amethyst Index. \n\nWe use the Meilisearch Open-Source project to provide you with the best possible Search Suggestions while keeping your privacy.\n")
                            .font(.system(size: 18))
                        Button("Autoconfigure & Download Amethyst Index") {
                            autoconfig()
                            downloader.chooseLocationAndStartDownload(from: URL(string: Bundle.main.infoDictionary?["IndexURL"] as? String ?? "")!)
                        }
                        .disabled(downloader.state.withLock { state in state } == .downloading)
                    }
                    if downloader.state.withLock({ state in state }) == .downloading {
                        Text("Downloading Amethyst Index")
                        ProgressView(value: downloader.progress.withLock { progress in progress })
                    }
                    if downloader.state.withLock({ state in state }) == .finished {
                        Image("IndexKeychainPermission")
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        Text("""
                        1. Open Download Destination
                        2. unzip Amethyst Index
                        3. move it to the Applications folder
                        4. start it
                        5. Enter your password and click Always Allow if asked for Keychain Access permission
                        6. continue to next page
                        """)
                        .font(.system(size: 14))
                    }
                    if downloader.state.withLock({ state in state }) == .failed {
                        Text("An error occured, please try again later")
                    }
                    if downloader.state.withLock({ state in state }) != .downloading && downloader.state.withLock({ state in state }) != .failed {
                        Button("Autoconfigure") { autoconfig() }
                    }
                }
                .frame(height: 300)
                .frame(maxWidth: 400)
            }
        }
        
        func autoconfig() {
            if let _ = KeyChainManager.getValue(for: .meiliMasterKey) {} else {
                guard let masterKey = KeyChainManager.generateSecureKey(length: 16) else {
                    return
                }
                KeyChainManager.setValue(masterKey, for: .meiliMasterKey)
            }
        }
        
        final class FileDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
            static let logger = Logger(subsystem: AmethystApp.subSystem, category: "IndexFileDownloader")
            enum DownloadState: Int {
                case idle
                case downloading
                case finished
                case failed
            }
            
            // Published properties will trigger UI updates in any listening SwiftUI view.
            let progress = Mutex(0.0)
            let state = Mutex(DownloadState.idle)

            private let downloadTask: Mutex<URLSessionDownloadTask?> = Mutex(nil)
            private let destinationURL: Mutex<URL?> = Mutex(nil)
            
            private var urlSession: URLSession {
                // We need a delegate to receive progress updates, so we configure the session with self as the delegate.
                let configuration = URLSessionConfiguration.default
                return URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
            }
            
            @MainActor
            func chooseLocationAndStartDownload(from url: URL) {
                defer { objectWillChange.send() }
                let savePanel = NSSavePanel()
                savePanel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                savePanel.canCreateDirectories = true
                savePanel.nameFieldStringValue = "Amethyst Index.zip"
                
                // show dialog
                savePanel.begin { [weak self] (result) in
                    guard let self = self, result == .OK, let destination = savePanel.url else {
                        // error or user cancellation
                        self?.state.withLock { state in state = .idle }
                        return
                    }
                    
                    // Save user selected url
                    self.destinationURL.withLock{ url in url = destination }
                    self.startDownload(from: url)
                }
            }

            // Starts the download process.
            private func startDownload(from url: URL) {
                self.progress.withLock { progress in progress = 0.0 }
                self.state.withLock { state in state = .downloading }
                
                let urlRequest = URLRequest(url: url)
                downloadTask.withLock { task in
                    task = urlSession.downloadTask(with: urlRequest)
                    task?.resume()
                }
                
                objectWillChange.send()
            }

            // MARK: - URLSessionDownloadDelegate Methods

            // This delegate method is called periodically with progress updates.
            func urlSession(
                _ session: URLSession,
                downloadTask: URLSessionDownloadTask,
                didWriteData bytesWritten: Int64,
                totalBytesWritten: Int64,
                totalBytesExpectedToWrite: Int64
            ) {
                let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                self.progress.withLock { prog in prog = progress }
                objectWillChange.send()
            }

            // This delegate method is called when the download successfully completes.
            func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
                defer { objectWillChange.send() }
                
                guard let destinationURL = self.destinationURL.withLock({ url in url }) else {
                    Self.logger.error("Error: Destination URL was not set.")
                    self.state.withLock { state in state = .failed }
                    return
                }
                
                let fileManager = FileManager.default
                do {
                    // delete potential old file at destination
                    try? fileManager.removeItem(at: destinationURL)
                    // move tmp to user selected destination
                    try fileManager.moveItem(at: location, to: destinationURL)
                    Self.logger.info("File moved to: \(destinationURL.path)")
                    self.state.withLock { state in state = .finished }
                } catch {
                    Self.logger.error("Download move failed with error: \(error.localizedDescription)")
                    self.state.withLock { state in state = .failed }
                }
            }

            // This delegate method is called when the task completes, either with an error or successfully.
            func urlSession(
                _ session: URLSession,
                task: URLSessionTask,
                didCompleteWithError error: Error?
            ) {
                // If there's an error, we update our state to reflect that.
                if let error = error {
                    Self.logger.error("Download failed with error: \(error.localizedDescription)")
                    self.state.withLock { state in state = .failed }
                    objectWillChange.send()
                }
            }
        }
    }
    
    private struct CheckMeiliRunning: View {
        @State var state: String = ""
        @Environment(\.dismiss) var dismiss
        @Environment(AppViewModel.self) var appViewModel
        @State var urlString = ""
        static var logger = Logger(subsystem: AmethystApp.subSystem, category: "SetupStep")
        var body: some View {
            VStack {
                Text("Check Setup")
                    .font(.title)
                Text("Now lets check Amethyst Index is running correctly real quick!")
                Button {
                    SwiftUI.Task {
                        urlString = MeiliSettings.meiliURL.stringValue(default: "127.0.0.1:37270")
                        guard !urlString.isEmpty, let url = URL(string: "http://\(urlString)") else { return }
                        var request = URLRequest(url: url)
                        request.httpMethod = "GET"
                        guard let key = KeyChainManager.getValue(for: .meiliMasterKey) else {
                            state = "Key missing in keychain. Please try again"
                            return
                        }
                        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                        do {
                            let res = try await URLSession.shared.data(for: request)
                            guard let response = res.1 as? HTTPURLResponse else {
                                return
                            }
                            if response.statusCode == 200 {
                                state = "Success!"
                            } else {
                                state = "An error occured. Please try setup again."
                            }
                        } catch {
                            state = "Amethyst Index seems not to be running. Please try starting it."
                        }
                    }
                } label: {
                    Text("check")
                }
                .buttonStyle(.borderless)
                Text(state)
                    .bold()
                    .foregroundStyle(state == "Success!" ? .green: .red)
                if state == "Success!" {
                    Button {
                        do {
                            appViewModel.meili = try MeiliSearch(host: "http://\(urlString)", apiKey: KeyChainManager.getValue(for: .meiliMasterKey))
                            UDKey.wasSetupOnce.boolValue = true
                        } catch {
                            Self.logger.error("An Error occured while setting up Meilisearch connection: \(error)")
                        }
                        dismiss()
                    } label: {
                        Text("Finish Setup")
                            .font(.title2)
                            .bold()
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
    
    private struct SetupLoginItems: View {
        var body: some View {
            VStack {
                Text("Setup Login Item")
                    .font(.title)
                Image("LoginItems")
                    .setupImageStyle()
                Text("Congratulations! You're almost there! The last step ist to configure your Automator-App to open at login. For that click on \"Open Login-Items\". That Button will bring you directly in the Settings to the Login Items. There just click on the plus, like marked in the image above and add you Automator App!")
                    .padding(.horizontal, 30)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("Open Login-Items")
                }
                .buttonStyle(.borderless)
                .padding(.bottom, 10)
            }
        }
    }
}

#Preview {
    Setup()
}
