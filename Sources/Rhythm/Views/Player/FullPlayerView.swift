import SwiftUI

struct FullPlayerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showLyrics: Bool = false
    
    var body: some View {
        ZStack {
            // MARK: - Dynamic Blurred Album Background
            if let track = playerVM.currentTrack {
                AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 65)
                            .scaleEffect(1.2)
                    } else {
                        Color.appBackgroundSecondary
                    }
                }
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.55).ignoresSafeArea())
            } else {
                Color.appBackground.ignoresSafeArea()
            }
            
            // MARK: - Foreground Content
            VStack(spacing: 0) {
                // Top Grabber & Dismiss
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        playerVM.showFullPlayer = false
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Center Grabber Indicator
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 36, height: 5)
                    
                    Spacer()
                    
                    // Lyrics Indicator Badge / Quick Toggle
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showLyrics.toggle()
                        }
                    } label: {
                        Image(systemName: showLyrics ? "quote.bubble.fill" : "quote.bubble")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(showLyrics ? .white : .white.opacity(0.8))
                            .frame(width: 44, height: 44)
                            .background(showLyrics ? Color.appAccentPink : Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                
                Spacer().frame(height: 12)
                
                // MARK: - Middle View: Either Big Cover OR Inline Animated Lyrics
                ZStack {
                    if showLyrics {
                        // Inline Synced Lyrics Overlay
                        AnimatedLyricsView()
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        // Big Cover Artwork
                        coverArtSection
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // MARK: - Track Info (Compact when lyrics open, full when cover open)
                if let track = playerVM.currentTrack {
                    HStack(alignment: .center, spacing: 14) {
                        if showLyrics {
                            // Mini thumbnail when lyrics are visible
                            AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Color.appSurface
                                }
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(radius: 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.system(size: showLyrics ? 18 : 22, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(track.artist)
                                .font(.system(size: showLyrics ? 14 : 17, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Heart / Save Button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            libraryVM.toggleSaved(track: track)
                        } label: {
                            Image(systemName: libraryVM.isTrackSaved(track) ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundColor(libraryVM.isTrackSaved(track) ? .appAccentPink : .white.opacity(0.8))
                                .scaleEffect(libraryVM.isTrackSaved(track) ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: libraryVM.isTrackSaved(track))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }
                
                // MARK: - Progress & Timers
                VStack(spacing: 6) {
                    PlayerProgressBar()
                    
                    HStack {
                        Text(formatTime(playerVM.currentTime))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextSecondary)
                        
                        Spacer()
                        
                        Text(formatTime(max(0, playerVM.duration - playerVM.currentTime)))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                
                // MARK: - Playback Controls
                HStack(spacing: 28) {
                    // Shuffle
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        playerVM.toggleShuffle()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(playerVM.isShuffled ? .appAccentPink : .white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Previous
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        playerVM.previous()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    // Big Play / Pause Button
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        playerVM.togglePlayPause()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.appAccentGradient)
                                .frame(width: 72, height: 72)
                                .shadow(color: .appAccentPink.opacity(0.5), radius: 14, x: 0, y: 5)
                            
                            if playerVM.isLoadingStream {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.2)
                            } else {
                                Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .offset(x: playerVM.isPlaying ? 0 : 2)
                            }
                        }
                    }
                    
                    // Next
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        playerVM.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Repeat
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        playerVM.toggleRepeat()
                    } label: {
                        Image(systemName: playerVM.repeatMode.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(playerVM.repeatMode.isActive ? .appAccentPink : .white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                
                // MARK: - Bottom Bar (AirPlay + Fullscreen Lyrics Toggle)
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "airplayaudio")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showLyrics.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 14))
                            Text(showLyrics ? "Скрыть текст" : "Текст песни")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(showLyrics ? .white : .white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(showLyrics ? Color.appAccentPink.opacity(0.8) : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Cover Art Section
    
    private var coverArtSection: some View {
        VStack {
            Spacer()
            
            if let track = playerVM.currentTrack {
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
                        }
                    case .failure:
                        ZStack {
                            Color.appSurface
                            Image(systemName: "music.note")
                                .font(.system(size: 60))
                                .foregroundColor(.appTextSecondary)
                        }
                    @unknown default:
                        Color.appSurface
                    }
                }
                .aspectRatio(1.0, contentMode: .fit)
                .frame(maxWidth: 320, maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.6), radius: 28, x: 0, y: 14)
                .scaleEffect(playerVM.isPlaying ? 1.0 : 0.92)
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: playerVM.isPlaying)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helper
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
