import SwiftUI

struct TrackCardView: View {
    let track: Track
    @EnvironmentObject var playerVM: PlayerViewModel
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                case .empty:
                    placeholder
                        .shimmer(isActive: true)
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)

            Text(track.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(track.artist)
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
                .lineLimit(1)
        }
        .frame(width: 160)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            playerVM.play(track: track)
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color.appSurface)
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 32))
                    .foregroundColor(.appTextSecondary)
            }
    }
}
