import SwiftUI

extension View {
    func glassBackground(cornerRadius: CGFloat = 16) -> some View {
        self.background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    var isActive: Bool
    
    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.2), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: -geo.size.width + phase * geo.size.width * 3)
                    }
                    .clipped()
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func shimmer(isActive: Bool) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
