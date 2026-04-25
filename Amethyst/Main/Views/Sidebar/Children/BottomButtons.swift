import SwiftUI

struct SidebarBottomButtonLabel: View {
    @State var playAnimation: Bool = false
    @State var isHovered = false
    
    let imageName: String
    
    var body: some View {
        Image(systemName: imageName)
            .sizeRef { Image(systemName: "arrow.down.app").font(.title) }
            .font(.title)
            .foregroundStyle(.gray.mix(with: .mainColorMix, by: 0.3))
            .symbolEffect(.wiggle.down.byLayer, value: playAnimation)
            .padding(5)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .padding(-2)
            .onHover { isHovered in
                if isHovered {
                    playAnimation.toggle()
                }
                self.isHovered = isHovered
            }
    }
}
