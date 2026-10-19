import SwiftUI

struct ShimmerView: View {
    var width: CGFloat = 100
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.appSurface)
            .frame(width: width, height: height)
            .shimmer(isActive: true)
    }
}
