import SwiftUI

struct RadialMenuAction {
    let label: AnyView
    let handler: () -> Void
    
    init<ActionLabel: View>(@ViewBuilder label: @escaping () -> ActionLabel, handler: @escaping () -> Void) {
        self.label = AnyView(label())
        self.handler = handler
    }
}

struct RadialMenu<Label: View>: View {
    let actions: [RadialMenuAction]
    var radius: CGFloat = 72
    
    var startAngle: Double = -180
    var endAngle: Double = 0
    
    @ViewBuilder
    let label: (Bool) -> Label
    @State private var isExpanded = false
    
    var body: some View {
        ZStack {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                Button { action.handler() } label: {
                    action.label
                }
                .buttonStyle(.plain)
                .offset(offset(for: index))
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.4)
                .allowsHitTesting(isExpanded)
                .animation(
                    .spring(response: 0.35, dampingFraction: 0.7)
                    .delay(Double(index) * 0.04),
                    value: isExpanded
                )
            }
            
            Button {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            } label: {
                label(isExpanded)
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.3), value: isExpanded)
        }
        .buttonStyle(.plain)
    }
    
    private func offset(for index: Int) -> CGSize {
        let angle = angleRadians(for: index)
        return CGSize(
            width: radius * cos(angle),
            height: radius * sin(angle)
        )
    }
    
    private func angleRadians(for index: Int) -> Double {
        let count = actions.count
        // Evenly distribute; if only 1 item, center it in the arc
        let t = count > 1 ? Double(index) / Double(count - 1) : 0.5
        let degrees = startAngle + t * (endAngle - startAngle)
        return degrees * .pi / 180
    }
}
