import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    
    var body: some View {
        if let track = playerVM.currentTrack {
            VStack(spacing: 0) {
                // Animated Glowing Accent Progress Line
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 2.5)
                        
                        Rectangle()
                            .fill(Color.appAccentGradient)
                            .frame(width: max(0, geo.size.width * CGFloat(playerVM.progress)), height: 2.5)
                            .animation(.linear(duration: 0.2), value: playerVM.progress)
                    }
                }
                .frame(height: 2.5)
                
                // Content Row
                HStack(spacing: 12) {
                    // Album Cover (Fixed 44x44 square with clipped bounds)
                    AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipped()
                        case .empty:
                            Color.appSurface
                                .frame(width: 44, height: 44)
                        case .failure:
                            ZStack {
                                Color.appSurface
                                Image(systemName: "music.note")
                                    .font(.system(size: 16))
                                    .foregroundColor(.appTextSecondary)
                            }
                            .frame(width: 44, height: 44)
                        @unknown default:
                            Color.appSurface
                                .frame(width: 44, height: 44)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 2)
                    
                    // Track Title & Artist
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Controls
                    HStack(spacing: 14) {
                        // Quick Like Button
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            libraryVM.toggleSaved(track: track)
                        } label: {
                            Image(systemName: libraryVM.isTrackSaved(track) ? "heart.fill" : "heart")
                                .font(.system(size: 18))
                                .foregroundColor(libraryVM.isTrackSaved(track) ? .appAccentPink : .white.opacity(0.6))
                                .frame(width: 32, height: 32)
                        }
                        
                        // Play / Pause Button with Neon Accent
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            playerVM.togglePlayPause()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                if playerVM.isLoadingStream {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .offset(x: playerVM.isPlaying ? 0 : 1)
                                }
                            }
                        }
                        
                        // Next Track Button
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            playerVM.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 58)
            }
            .background(
                ZStack {
                    // Glass blur
                    Rectangle().fill(.ultraThinMaterial)
                    
                    // Subtle dark gradient backing
                    LinearGradient(
                        colors: [Color(hex: "181828").opacity(0.85), Color(hex: "0D0D15").opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.45), radius: 16, x: 0, y: 8)
            .shadow(color: .appAccentPink.opacity(playerVM.isPlaying ? 0.15 : 0), radius: 20, x: 0, y: 6)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    playerVM.showFullPlayer = true
                }
            }
            .gesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onEnded { value in
                        if value.translation.height < -25 {
                            // Swipe up opens full player
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                playerVM.showFullPlayer = true
                            }
                        } else if value.translation.width < -40 {
                            // Swipe left for next
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            playerVM.next()
                        } else if value.translation.width > 40 {
                            // Swipe right for previous
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            playerVM.previous()
                        }
                    }
            )
        }
    }
}
