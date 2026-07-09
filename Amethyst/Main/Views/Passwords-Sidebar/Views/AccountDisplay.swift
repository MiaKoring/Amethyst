//
//  AccountDisplay.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 09.03.25.
//

import SwiftUI
import SwiftData
import AmethystAuthenticatorCore
import AuthenticationServices

struct AccountDisplay: View {
    var account: Account
    var context: ModelContext
    @State var showPopup: Bool = false
    @State var isHovered: Bool = false
    var interactionDisabled: Bool = false
    @State var edit: Bool = false
        
    var body: some View {
        HStack {
            ZStack {
                if let data = account.image, let nsImage = NSImage(data: data) {
                    WebsiteIcon(nsImage: nsImage)
                } else {
                    WebsiteIconPlaceholder(account: account)
                }
            }
            .padding(.trailing, 5)
            VStack(alignment: .leading) {
                {
                    if let title = account.title, !title.isEmpty {
                        Text(title)
                    } else {
                        Text(account.service)
                    }
                }()
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .bold()
                Text(account.username)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
            if isHovered {
                HStack {
                    if account.totp {
                        TOTPButton(account: account)
                    }
                    EditButton(edit: $edit)
                }
            }
        }
        .contextMenu {
            if !interactionDisabled {
                Button("Delete", role: .destructive) {
                    showPopup = true
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete this Account? It will be restorable for 30 days.", isPresented: $showPopup, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                account.delete()
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .sheet(isPresented: $edit) {
            AccountDetailEdit(account: account, create: false, context: context) {
                edit = false
            }
        }
    }
    
    struct TOTPButton: View {
        @State var isHovered: Bool = false
        @State var highlightCopied: Bool = false
        let account: Account
        var body: some View {
            Button {
                copyTOTPCode()
            } label: {
                Image(systemName: highlightCopied ? "checkmark.circle.fill": "key.viewfinder")
                    .font(.title2)
                    .foregroundStyle(.gray.opacity(0.8))
                    .background(isHovered && !highlightCopied ? .gray.opacity(0.2): .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
            }
        }
        
        private func copyTOTPCode() {
            withAnimation {
                highlightCopied = true
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(account.getCurrentTOTPCode() ?? "", forType: .string)
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
                Task { @MainActor in
                    withAnimation {
                        highlightCopied = false
                    }
                }
                timer.invalidate()
            }
        }
    }
    
    struct EditButton: View {
        @Binding var edit: Bool
        @State var isHovered: Bool = false
        var body: some View {
            Button {
                edit = true
            } label: {
                Image(systemName: "pencil.circle\(isHovered ? ".fill": "")")
                    .font(.title2)
                    .foregroundStyle(.gray.opacity(0.8))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }
    
    struct WebsiteIcon: View {
        let nsImage: NSImage
        var body: some View {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
    }
    
    struct WebsiteIconPlaceholder: View {
        let account: Account
        var body: some View {
            RoundedRectangle(cornerRadius: 5)
                .fill(.tertiary.opacity(0.5))
                .frame(width: 40, height: 40)
                .overlay {
                    {
                        if let first = account.title?.first?.uppercased() {
                            Text(first)
                        } else if let url = URL(string: account.service), let first = url.host()?.first?.uppercased() {
                            Text(first)
                        } else {
                            Text(account.service.first?.uppercased() ?? "")
                        }
                    }()
                        .font(.title)
                }
        }
    }
}
