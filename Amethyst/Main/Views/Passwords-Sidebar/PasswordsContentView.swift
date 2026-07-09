//
//  PasswordsContentView.swift
//  Amethyst Project
//
//  Created by Mia Koring on 10.04.25.
//

import SwiftUI
import SwiftData
@preconcurrency import LocalAuthentication
import AmethystAuthenticatorCore

struct PasswordsContentView: View {
    @State var isAuthenticated = false
    var context: ModelContext
    @State var timer: Timer?
    
    var body: some View {
        ZStack {
            if isAuthenticated {
                PasswordList(context: context)
            } else {
                ObscuringView(isAuthenticated: $isAuthenticated, timer: $timer)
            }
        }
        .onAppear() {
            isAuthenticated = UDKey.lastAuthTime.intValue + 60 * 30 > Int(Date.now.timeIntervalSinceReferenceDate)
            if isAuthenticated {
                timer = Timer.scheduledTimer(withTimeInterval: Double(UDKey.lastAuthTime.intValue + 60 * 30) - Date.now.timeIntervalSinceReferenceDate, repeats: false) { timer in
                    Task { @MainActor in
                        isAuthenticated = false
                    }
                    timer.invalidate()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    struct ObscuringView: View {
        @Binding var isAuthenticated: Bool
        @State var tryCode = false
        @Binding var timer: Timer?
        var body: some View {
            MeshGradient(width: 2, height: 2, points: [
                [0, 0], [1, 0],
                [0, 1], [1, 1]
            ], colors: [.reverse, .myPurple, .myPurple, .reverse])
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay {
                Button {
                    guard !isAuthenticated else { return }
                    if tryCode {
                        authenticate(withPasscode: true)
                    } else {
                        authenticate()
                    }
                } label: {
                    VStack {
                        Text("Unlock")
                            .font(.title2)
                            .bold()
                        Text("\(Keybind.triggerPasswordsAuth.shortcut.modifier.contains(.command) ? "⌘": "")\(Keybind.triggerPasswordsAuth.shortcut.modifier.contains(.shift) ? "⇧": "")\(Keybind.triggerPasswordsAuth.shortcut.modifier.contains(.option) ? "⌥": "")\(Keybind.triggerPasswordsAuth.shortcut.modifier.contains(.control) ? "⌃": "")\("\(Keybind.triggerPasswordsAuth.shortcut.key.character)".uppercased())")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
                .buttonStyle(.plain)
                .keyboardShortcut(Keybind.triggerPasswordsAuth.keyboardShortcut)
            }
        }
        
        func authenticate(withPasscode: Bool = false) {
            let context = LAContext()
            var error: NSError?
            let reason = "You need to unlock to access your credentials"
            
            guard !withPasscode else {
                authenticateWithPasscode()
                return
            }
            // check whether biometric authentication is possible
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {

                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    guard authenticationError == nil else {
                        Task { @MainActor in
                            tryCode = true
                        }
                        authenticateWithPasscode()
                        return
                    }
                    Task { @MainActor in
                        if success {
                            handleSuccess()
                        } else {
                            tryCode = true
                            authenticateWithPasscode()
                        }
                    }
                }
            } else {
                tryCode = true
                authenticateWithPasscode()
            }
            
            @Sendable func authenticateWithPasscode() {
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { completed, authenticationError in
                    Task { @MainActor in
                        if completed {
                            handleSuccess()
                        }
                    }
                }
            }
            
            @Sendable
            func handleSuccess() {
                Task { @MainActor in
                    isAuthenticated = true
                    UDKey.lastAuthTime.intValue = Int(Date.now.timeIntervalSinceReferenceDate)
                    tryCode = false
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: Double(UDKey.lastAuthTime.intValue + 60 * 30) - Date.now.timeIntervalSinceReferenceDate, repeats: false) { timer in
                        Task { @MainActor in
                            isAuthenticated = false
                        }
                        timer.invalidate()
                    }
                }
            }
        }
    }
}
