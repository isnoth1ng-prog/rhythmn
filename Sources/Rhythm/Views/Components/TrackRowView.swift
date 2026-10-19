import SwiftUI

struct TrackRowView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    let track: Track
    var trackNumber: Int? = nil
    let onTap: () -> Void
    
    private var isCurrentlyPlaying: Bool {
        playerVM.currentTrack?.id == track.id
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            HStack(spacing: 13) {
                // Track Number or Live Equalizer Indicator
                if let number = trackNumber {
                    if isCurrentlyPlaying && playerVM.isPlaying {
                        Image(systemName: "waveform")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.appAccentPink)
                            .frame(width: 24, alignment: .center)
                    } else {
                        Text("\(number)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(isCurrentlyPlaying ? .appAccentPink : .appTextSecondary)
                            .frame(width: 24, alignment: .center)
                    }
                }
                
                // Artwork Thumbnail (Square with clipped bounds)
                AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipped()
                    case .empty:
                        Color.appSurface
                            .frame(width: 50, height: 50)
                    case .failure:
                        ZStack {
                            Color.appSurface
                            Image(systemName: "music.note")
                                .font(.system(size: 18))
                                .foregroundColor(.appTextSecondary)
                        }
                        .frame(width: 50, height: 50)
                    @unknown default:
                        Color.appSurface
                            .frame(width: 50, height: 50)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(isCurrentlyPlaying ? Color.appAccentPink.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: isCurrentlyPlaying ? .appAccentPink.opacity(0.3) : .black.opacity(0.35), radius: 5, x: 0, y: 2)
                
                // Track Information
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 15, weight: isCurrentlyPlaying ? .bold : .medium, design: .rounded))
                        .foregroundColor(isCurrentlyPlaying ? .appAccentPink : .white)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Duration & Saved Heart Indicator
                HStack(spacing: 8) {
                    if libraryVM.isTrackSaved(track) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.appAccentPink)
                    }
                    
                    Text(track.formattedDuration)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(
                isCurrentlyPlaying
                    ? Color.appAccentPink.opacity(0.08)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                libraryVM.toggleSaved(track: track)
            } label: {
                Label(
                    libraryVM.isTrackSaved(track) ? "Удалить из библиотеки" : "Сохранить в избранное",
                    systemImage: libraryVM.isTrackSaved(track) ? "heart.slash" : "heart"
                )
            }
        }
    }
}
