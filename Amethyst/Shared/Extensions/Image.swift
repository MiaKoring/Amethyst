//
//  Image.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 17.12.24.
//

import SwiftUI

extension Image {
    @ViewBuilder
    func sidebarTopButton(hovered: Binding<Bool>, clicked: Binding<Bool>?, appearance: ColorScheme = .dark, useMacos26Design: Bool, onTap: @escaping () -> Void) -> some View {
        if #available(macOS 26, *), useMacos26Design {
            self.sidebarTopButton26(hovered: hovered, clicked: clicked, appearance: appearance, onTap: onTap)
        } else {
            self
                .symbolEffect(.wiggle, isActive: clicked?.wrappedValue ?? false)
                .font(.title2)
                .foregroundStyle(appearance == .dark ? Color.gray: Color.gray.mix(with: .black, by: 0.4))
                .padding(3)
                .background() {
                    if !hovered.wrappedValue {
                        Color.clear
                    } else {
                        Color.white.opacity(0.1)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .onHover { hovering in
                    withAnimation(.linear(duration: 0.07)) {
                        hovered.wrappedValue = hovering
                    }
                }
                .onTapGesture {
                    clicked?.wrappedValue = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        clicked?.wrappedValue = false
                    }
                    onTap()
                }
        }
    }
    @available(macOS 26.0, *)
    func sidebarTopButton26(hovered: Binding<Bool>, clicked: Binding<Bool>?, appearance: ColorScheme = .dark, onTap: @escaping () -> Void) -> some View {
        self
            .symbolEffect(.wiggle, isActive: clicked?.wrappedValue ?? false)
            .font(.title2)
            .foregroundStyle(appearance == .dark ? Color.gray: Color.gray.mix(with: .black, by: 0.4))
            .padding(5)
            .background() {
                if !hovered.wrappedValue {
                    Color.clear
                } else {
                    Color.white.opacity(0.1)
                }
            }
            .clipShape(Capsule())
            .onHover { hovering in
                withAnimation(.linear(duration: 0.07)) {
                    hovered.wrappedValue = hovering
                }
            }
            .onTapGesture {
                clicked?.wrappedValue = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    clicked?.wrappedValue = false
                }
                onTap()
            }
    }
    
    func sizeRef(_ view: @escaping () -> some View) -> some View {
        view()
            .hidden()
            .overlay {
                self
                    .resizable()
                    .scaledToFit()
            }
    }
    
    func setupImageStyle() -> some View {
        self
            .resizable()
            .scaledToFit()
            .shadow(color: .myPurple, radius: 10)
            .padding(.horizontal, 30)
    }
}
