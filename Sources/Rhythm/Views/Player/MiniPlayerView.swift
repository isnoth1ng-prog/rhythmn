import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    
    var body: some View {
        if let track = playerVM.currentTrack {
            VStack(spacing: 0) {
                // Progress Bar at the top of mini player
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 2.5)
                        
                        Rectangle()
                            .fill(Color.appAccentGradient)
                            .frame(width: geo.size.width * CGFloat(playerVM.progress), height: 2.5)
                            .animation(.linear(duration: 0.25), value: playerVM.progress)
                    }
                }
                .frame(height: 2.5)
                
                // Content Row
                HStack(spacing: 12) {
                    // Thumbnail
                    AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .empty:
                            Color.appSurface
                        case .failure:
                            Image(systemName: "music.note")
                                .foregroundColor(.appTextSecondary)
                        @unknown default:
                            Color.appSurface
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    
                    // Track Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Controls
                    HStack(spacing: 16) {
                        // Play / Pause
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            playerVM.togglePlayPause()
                        } label: {
                            if playerVM.isLoadingStream {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Next
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            playerVM.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 56)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                playerVM.showFullPlayer = true
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        if value.translation.height < -30 {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            playerVM.showFullPlayer = true
                        }
                    }
            )
        }
    }
}
