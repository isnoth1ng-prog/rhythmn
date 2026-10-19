import SwiftUI

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
