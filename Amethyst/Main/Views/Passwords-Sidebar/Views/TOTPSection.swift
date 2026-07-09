//
//  TOTPSection.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 11.03.25.
//

import SwiftUI
import AmethystAuthenticatorCore

struct TOTPSection: View {
    @Bindable var account: Account
    @Binding var deleteAction: DeleteAction?
    @State var showAddVerificationCodeAlert: Bool = false
    
    var body: some View {
        Section {
            HStack {
                Text("Verification Code")
                Spacer()
                VerificationCodeView(account: account)
            }
            .alert("Add Verification Code", isPresented: $showAddVerificationCodeAlert) {
                TOTPInputView() { key in
                    account.setTOTPSecret(to: key.replacingOccurrences(of: " ", with: ""))
                    showAddVerificationCodeAlert = false
                }
                Button("Cancel", role: .cancel) {
                    showAddVerificationCodeAlert = false
                }
            }
            if account.totp {
                Button("Delete Verification Code", role: .destructive) {
                    deleteAction = .code
                }
            } else {
                Button("Setup Verification Code") {
                    showAddVerificationCodeAlert = true
                }
            }
        }
    }
    
    struct TOTPInputView: View {
        let completion: (String) -> Void
        @State var totpSecret: String = ""
        var body: some View {
            TextField("Setup Key", text: $totpSecret)
            Button("Use Setup Key") {
                completion(totpSecret)
            }
            .disabled(totpSecret.isEmpty)
        }
    }
    
    struct VerificationCodeView: View {
        let account: Account
        @State var totpCode: String?
        @State var totpTimer: Timer?
        var body: some View {
            Menu {
                Button("Copy Verification Code") {
                    NSPasteboard.general.setString(totpCode?.replacingOccurrences(of: " ", with: "") ?? "", forType: .string)
                }
            } label: {
                Text(totpCode ?? "--- ---")
                    .monospaced()
                    .bold()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double((totpCode ?? "000 000").replacingOccurrences(of: " ", with: "")) ?? 0))
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .onAppear() { if account.totp { handleTOTPonAppear() } }
        }
        
        func handleTOTPonAppear() {
            self.totpCode = getCurrentTOTP()
            scheduleNextTOTPUpdate()
        }
        
        func scheduleNextTOTPUpdate() {
            totpTimer?.invalidate()
            let remainingTime = AuthenticatorHelper.getRemainingTOTPTime()
            let nextUpdateTime = max(0.1, Double(remainingTime) + 0.1)

            totpTimer = Timer.scheduledTimer(withTimeInterval: nextUpdateTime, repeats: false) {_ in
                Task { @MainActor in
                    withAnimation {
                        self.totpCode = self.getCurrentTOTP()
                    }
                    self.scheduleNextTOTPUpdate()
                }
            }
        }
        
        func getCurrentTOTP() -> String {
            guard var code  = account.getCurrentTOTPCode() else {
                return "Error"
            }
            code.insert(" ", at: code.index(code.startIndex, offsetBy: 3))
            return code
        }
    }

}

