//
//  Untitled.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 11.03.25.
//

import SwiftUI
import AmethystAuthenticatorCore
import SwiftData
import OSLog

@MainActor
struct AccountDetailEdit {
    @Bindable var account: Account
    @Query var accounts: [Account]
    @State var username: String = ""
    @State var password: String = ""
    @State var title: String
    @State var deleteAction: DeleteAction?
    @State var error: AAuthenticationError? = nil
    @State var create: Bool
    var confirmationActionDisabled: Bool {
        create && (title.hasPrefix(".") || title.hasSuffix(".") || !title.contains(".") || username.isEmpty || password.isEmpty)
    }
    var onClose: () -> Void
    var context: ModelContext
    static let logger = Logger(subsystem: AmethystApp.subSystem, category: "AccountDetailEdit")
    
    
    init(account: Account, create: Bool = false, context: ModelContext, onClose: @escaping () -> Void) {
        self.account = account
        self.username = account.username
        self.context = context
        
        if !create {
            self.password = account.password ?? ""
        } else {
            self.password = ""
        }
        
        if create {
            self.title = account.service
        } else {
            self.title = account.title ?? ""
        }
        
        self.create = create
        self.onClose = onClose
    }
    
    init(service: String, context: ModelContext, onClose: @escaping () -> Void) {
        self.context = context
        self.account = Account(service: "", username: "", totp: false)
        self.title = service
        self.create = true
        self.onClose = onClose
    }
    
    func save() {
        guard let context = account.modelContext else {
            print("account without context")
            return
        }
        do {
            try context.transaction {
                if account.title != title {
                    account.setTitle(to: title)
                }
                if !password.isEmpty {
                    let strength = AuthenticatorHelper.evaluatePasswordStrength(password: password)
                    account.strength = strength
                    account.setPassword(to: password)
                } else {
                    if account.password != nil {
                        account.setPassword(to: nil)
                    }
                }
                if account.username != username && !username.isEmpty {
                    do {
                        try account.setUsername(to: username, allAccounts: accounts, context: context)
                    } catch {
                        if let error = error as? AAuthenticationError {
                            self.error = error
                        } else {
                            print(error)
                        }
                        return
                    }
                }
            }
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
        onClose()
    }
    
    func handleDeletionAndRestoration() {
        if account.deletedAt != nil {
            account.restore()
        } else {
            deleteAction = .account
        }
    }
    
    
    func executeDeletion() {
        switch deleteAction {
        case .code:
            account.removeTOTPSecret()
        case .password:
            account.setPassword(to: nil)
            password = ""
        case .passkey:
            //TODO: Add passkey support
            break
        case .account:
            account.delete()
        case nil:
            break
        }
        deleteAction = nil
    }
    
    func confirmAction() {
        guard create else {
            save()
            return
        }
        let strength = AuthenticatorHelper.evaluatePasswordStrength(password: password)
        do {
            try context.transaction {
                let newAccount = try Account(service: title, username: username, comment: "", password: password, allAccounts: accounts, strength: strength)
                
                let service = newAccount.service
                Task {
                    async let title = try? await Account.getTitle(from: service)
                    async let image = try? await Account.getImage(for: service)
                    
                    await newAccount.setImage(to: image)
                    if let title = await title {
                        newAccount.setTitle(to: title )
                    }
                }
                context.insert(newAccount)
            }
        } catch {
            if let error = error as? AAuthenticationError {
                self.error = error
            } else {
                Self.logger.debug("\(error.localizedDescription)")
            }
        }
        onClose()
    }
    
}

