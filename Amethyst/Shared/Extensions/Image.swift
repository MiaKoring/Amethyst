//
//  Image.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 17.12.24.
//

import SwiftUI

private struct ClickableSidebarIconModifier: ViewModifier {
    let hovered: Binding<Bool>
    let clickAnimated: Bool
    let onTap: () -> Void
    
    @State private var clicked = false
    @State private var pendingReset: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .symbolEffect(.wiggle, isActive: clicked && clickAnimated)
            .onHover { hovering in
                withAnimation(.linear(duration: 0.07)) {
                    hovered.wrappedValue = hovering
                }
            }
            .onTapGesture {
                pendingReset?.cancel()
                
                onTap()
                clicked = true
                
                let item = DispatchWorkItem {
                    clicked = false
                }
                pendingReset = item
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: item)
            }
    }
}

extension Image {
    @ViewBuilder
    func sidebarTopButton(hovered: Binding<Bool>, clickAnimated: Bool = true, appearance: ColorScheme = .dark, useMacos26Design: Bool, onTap: @escaping () -> Void) -> some View {
        if #available(macOS 26, *), useMacos26Design {
            self.sidebarTopButton26(hovered: hovered, clickAnimated: clickAnimated, appearance: appearance, onTap: onTap)
        } else {
            self
                .font(.title2)
                .foregroundStyle(
                    appearance == .dark ?
                        Color.gray:
                        Color.gray.mix(with: .black, by: 0.4)
                )
                .padding(3)
                .background {
                    hovered.wrappedValue ? Color.white.opacity(0.1) : Color.clear
                }
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .clickableSidebarIcon(
                    hovered: hovered,
                    clickAnimated: clickAnimated,
                    onTap: onTap
                )
        }
    }
    
    @available(macOS 26.0, *)
    func sidebarTopButton26(hovered: Binding<Bool>, clickAnimated: Bool = true, appearance: ColorScheme = .dark, onTap: @escaping () -> Void) -> some View {
        self
            .font(.title2)
            .foregroundStyle(
                appearance == .dark ?
                    Color.gray:
                    Color.gray.mix(with: .black, by: 0.4)
            )
            .padding(5)
            .background {
                hovered.wrappedValue ? Color.white.opacity(0.1) : Color.clear
            }
            .clipShape(Capsule())
            .clickableSidebarIcon(
                hovered: hovered,
                clickAnimated: clickAnimated,
                onTap: onTap
            )
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

private extension View {
    func clickableSidebarIcon(
        hovered: Binding<Bool>,
        clickAnimated: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        modifier(
            ClickableSidebarIconModifier(
                hovered: hovered,
                clickAnimated: clickAnimated,
                onTap: onTap
            )
        )
    }
}
