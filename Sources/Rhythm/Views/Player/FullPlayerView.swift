import SwiftUI

struct FullPlayerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showLyrics: Bool = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { screenGeo in
            ZStack {
                // MARK: - Dynamic Ambient Background with Deep Blur
                ambientBackground
                
                // MARK: - Main Player Content
                VStack(spacing: 0) {
                    // Safe-Area Aware Header & Dismiss Grabber
                    topHeaderBar
                        .padding(.top, max(12, screenGeo.safeAreaInsets.top > 0 ? screenGeo.safeAreaInsets.top : 24))
                    
                    Spacer(minLength: 8)
                    
                    // Middle Section: Artwork OR Animated Synced Lyrics
                    if showLyrics {
                        AnimatedLyricsView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    } else {
                        artworkSection(screenSize: screenGeo.size)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Track Information Row
                    if let track = playerVM.currentTrack {
                        trackInfoRow(track: track)
                    }
                    
                    // Progress Scrubber & Timers
                    progressSection
                        .padding(.top, 8)
                    
                    // Primary Playback Controls
                    playbackControlsSection
                        .padding(.vertical, 16)
                    
                    // Bottom Utility Bar (AirPlay, Lyrics, Queue)
                    bottomUtilityBar
                        .padding(.bottom, max(20, screenGeo.safeAreaInsets.bottom > 0 ? screenGeo.safeAreaInsets.bottom : 20))
                }
                .padding(.horizontal, 22)
            }
            .offset(y: max(0, dragOffset))
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8), value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 || value.predictedEndTranslation.height > 200 {
                            closePlayer()
                        } else {
                            dragOffset = 0
                        }
                    }
            )
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Top Header Bar
    
    private var topHeaderBar: some View {
        HStack(alignment: .center) {
            // Dismiss Button (Large 44x44 tap target, clearly visible below Dynamic Island)
            Button {
                closePlayer()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .contentShape(Rectangle())
            
            Spacer()
            
            // Central Pill Grabber (also tappable to dismiss)
            VStack(spacing: 3) {
                Capsule()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 38, height: 5)
                
                Text(showLyrics ? "Текст песни" : "Сейчас играет")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.appTextSecondary)
                    .textCase(.uppercase)
            }
            .onTapGesture {
                closePlayer()
            }
            
            Spacer()
            
            // Quick Lyrics Toggle in Header
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showLyrics.toggle()
                }
            } label: {
                Image(systemName: showLyrics ? "quote.bubble.fill" : "quote.bubble")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(showLyrics ? .white : .white.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .background(showLyrics ? Color.appAccentPink : Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Square Proportional Cover Artwork
    
    private func artworkSection(screenSize: CGSize) -> some View {
        VStack {
            Spacer()
            
            if let track = playerVM.currentTrack {
                let maxDimension = min(screenSize.width - 56, screenSize.height * 0.38, 330)
                
                AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: maxDimension, height: maxDimension)
                            .clipped()
                    case .empty:
                        ZStack {
                            Color.appSurface
                            ProgressView()
                                .tint(.appAccentPink)
                                .scaleEffect(1.2)
                        }
                        .frame(width: maxDimension, height: maxDimension)
                    case .failure:
                        ZStack {
                            Color.appSurface
                            Image(systemName: "music.note")
                                .font(.system(size: 64))
                                .foregroundColor(.appTextSecondary)
                        }
                        .frame(width: maxDimension, height: maxDimension)
                    @unknown default:
                        Color.appSurface
                            .frame(width: maxDimension, height: maxDimension)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.65), radius: 30, x: 0, y: 15)
                .shadow(color: .appAccentPink.opacity(playerVM.isPlaying ? 0.25 : 0), radius: 40, x: 0, y: 10)
                .scaleEffect(playerVM.isPlaying ? 1.0 : 0.90)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: playerVM.isPlaying)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Track Info
    
    private func trackInfoRow(track: Track) -> some View {
        HStack(alignment: .center, spacing: 14) {
            if showLyrics {
                // Mini album thumbnail when lyrics mode is on
                AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.appSurface
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(radius: 6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: showLyrics ? 19 : 23, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: showLyrics ? 15 : 17, weight: .medium, design: .rounded))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Heart Save / Favorite
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                libraryVM.toggleSaved(track: track)
            } label: {
                Image(systemName: libraryVM.isTrackSaved(track) ? "heart.fill" : "heart")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(libraryVM.isTrackSaved(track) ? .appAccentPink : .white.opacity(0.85))
                    .scaleEffect(libraryVM.isTrackSaved(track) ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: libraryVM.isTrackSaved(track))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Progress & Timers
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            PlayerProgressBar()
            
            HStack {
                Text(formatTime(playerVM.currentTime))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.appTextSecondary)
                
                Spacer()
                
                Text("-" + formatTime(max(0, playerVM.duration - playerVM.currentTime)))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
    
    // MARK: - Playback Controls
    
    private var playbackControlsSection: some View {
        HStack(spacing: 0) {
            // Shuffle Button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                playerVM.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(playerVM.isShuffled ? .appAccentPink : .white.opacity(0.65))
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Previous Track
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                playerVM.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
            }
            
            Spacer()
            
            // Giant Neon Play / Pause Button
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                playerVM.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.appAccentGradient)
                        .frame(width: 76, height: 76)
                        .shadow(color: .appAccentPink.opacity(0.55), radius: 18, x: 0, y: 6)
                    
                    if playerVM.isLoadingStream {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.25)
                    } else {
                        Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                            .offset(x: playerVM.isPlaying ? 0 : 2)
                    }
                }
            }
            
            Spacer()
            
            // Next Track
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                playerVM.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
            }
            
            Spacer()
            
            // Repeat Button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                playerVM.toggleRepeat()
            } label: {
                Image(systemName: playerVM.repeatMode.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(playerVM.repeatMode.isActive ? .appAccentPink : .white.opacity(0.65))
                    .frame(width: 44, height: 44)
            }
        }
    }
    
    // MARK: - Bottom Utility Bar
    
    private var bottomUtilityBar: some View {
        HStack {
            // AirPlay indicator (decorative)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "airplayaudio")
                    .font(.system(size: 19))
                    .foregroundColor(.white.opacity(0.65))
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Synced Lyrics Toggle Button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showLyrics.toggle()
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 14))
                    Text(showLyrics ? "Скрыть текст" : "Текст песни")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(showLyrics ? .white : .white.opacity(0.85))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(showLyrics ? Color.appAccentPink : Color.white.opacity(0.12))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // Queue / Playlist button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 19))
                    .foregroundColor(.white.opacity(0.65))
                    .frame(width: 44, height: 44)
            }
        }
    }
    
    // MARK: - Ambient Background
    
    private var ambientBackground: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            if let track = playerVM.currentTrack {
                AsyncImage(url: URL(string: track.thumbnailUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 75)
                            .scaleEffect(1.2)
                    } else {
                        Color.appBackgroundSecondary
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay(Color.black.opacity(0.55))
            }
            
            // Ambient neon light flare
            RadialGradient(
                colors: [.appAccentPink.opacity(0.16), .clear],
                center: .top,
                startRadius: 20,
                endRadius: 360
            )
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Helpers
    
    private func closePlayer() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            playerVM.showFullPlayer = false
            dismiss()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
