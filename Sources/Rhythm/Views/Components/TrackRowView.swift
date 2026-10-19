import SwiftUI

struct TrackRowView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    let track: Track
    var trackNumber: Int? = nil
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                if let number = trackNumber {
                    Text("\(number)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 24, alignment: .center)
                }
                
                // Thumbnail
                AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        ZStack {
                            Color.appSurface
                            ProgressView()
                                .tint(.appAccentPink)
                                .scaleEffect(0.6)
                        }
                    case .failure:
                        ZStack {
                            Color.appSurface
                            Image(systemName: "music.note")
                                .foregroundColor(.appTextSecondary)
                        }
                    @unknown default:
                        Color.appSurface
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Duration & heart indicator
                HStack(spacing: 8) {
                    if libraryVM.isTrackSaved(track) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.appAccentPink)
                    }
                    
                    Text(track.formattedDuration)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                libraryVM.toggleSaved(track: track)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Label(
                    libraryVM.isTrackSaved(track) ? "Удалить из библиотеки" : "Сохранить в библиотеку",
                    systemImage: libraryVM.isTrackSaved(track) ? "heart.slash" : "heart"
                )
            }
        }
    }
}
