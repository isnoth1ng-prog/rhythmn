import SwiftUI

struct TrackCardView: View {
    let track: Track
    @EnvironmentObject var playerVM: PlayerViewModel
    @State private var isPressed = false

    private var isPlayingThis: Bool {
        playerVM.currentTrack?.id == track.id
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            playerVM.play(track: track)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Artwork Container with Floating Play Badge
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 156, height: 156)
                                .clipped()
                        case .failure, .empty:
                            ZStack {
                                Color.appSurface
                                Image(systemName: "music.note")
                                    .font(.system(size: 36))
                                    .foregroundColor(.appTextSecondary)
                            }
                            .frame(width: 156, height: 156)
                        @unknown default:
                            Color.appSurface
                                .frame(width: 156, height: 156)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isPlayingThis ? Color.appAccentPink : Color.white.opacity(0.12), lineWidth: isPlayingThis ? 2 : 1)
                    )
                    
                    // Floating Play / Waveform Badge
                    ZStack {
                        Circle()
                            .fill(isPlayingThis ? Color.appAccentPink : Color.black.opacity(0.65))
                            .frame(width: 38, height: 38)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        
                        Image(systemName: isPlayingThis && playerVM.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: (isPlayingThis && playerVM.isPlaying) ? 0 : 1)
                    }
                    .padding(10)
                    .shadow(radius: 6)
                }
                .shadow(color: isPlayingThis ? .appAccentPink.opacity(0.35) : .black.opacity(0.4), radius: 10, x: 0, y: 5)

                // Track Details
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isPlayingThis ? .appAccentPink : .white)
                        .lineLimit(1)

                    Text(track.artist)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
                .frame(width: 156, alignment: .leading)
            }
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
