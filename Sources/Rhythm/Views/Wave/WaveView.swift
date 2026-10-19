import SwiftUI

struct WaveView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @StateObject private var waveVM = WaveViewModel()
    
    @State private var phase: CGFloat = 0
    @State private var barHeights: [CGFloat] = [18, 42, 28, 58, 38, 70, 32, 52, 24, 62, 42, 28, 50, 35]
    
    private let timer = Timer.publish(every: 0.22, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Ethereal Animated Nebula Background
                ambientBackground
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        Spacer().frame(height: 10)
                        
                        // MARK: - Hero Glowing Waveform Orb
                        VStack(spacing: 16) {
                            ZStack {
                                // Pulsing ambient rings
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [.appAccentPink.opacity(0.4), .appAccentPurple.opacity(0.15), .clear],
                                            center: .center,
                                            startRadius: 15,
                                            endRadius: 100
                                        )
                                    )
                                    .frame(width: 200, height: 200)
                                    .scaleEffect(waveVM.isActive ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: waveVM.isActive)
                                
                                Image(systemName: "waveform.circle.fill")
                                    .font(.system(size: 100))
                                    .foregroundStyle(Color.appAccentGradient)
                                    .shadow(color: .appAccentPink.opacity(0.7), radius: 25, x: 0, y: 10)
                            }
                            
                            VStack(spacing: 6) {
                                Text("Моя Волна")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Бесконечный умный поток музыки, подбирающийся на ходу под ваш вкус")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.appTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        
                        // MARK: - Live Dancing Audio Spectrum Bars
                        HStack(spacing: 6) {
                            ForEach(0..<barHeights.count, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.appAccentGradient)
                                    .frame(width: 4, height: playerVM.isPlaying && waveVM.isActive ? barHeights[index] : 8)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.55), value: barHeights[index])
                            }
                        }
                        .frame(height: 80)
                        
                        // MARK: - Start / Control Button
                        Button {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            if waveVM.isActive {
                                playerVM.togglePlayPause()
                            } else {
                                waveVM.startWave(playerVM: playerVM)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                if waveVM.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: waveVM.isActive && playerVM.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 22, weight: .bold))
                                }
                                
                                Text(waveVM.isActive ? (playerVM.isPlaying ? "Остановить волну" : "Продолжить волну") : "Запустить Мою Волну")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.appAccentGradient)
                            .clipShape(Capsule())
                            .shadow(color: .appAccentPink.opacity(0.55), radius: 18, x: 0, y: 7)
                        }
                        .padding(.horizontal, 28)
                        
                        // MARK: - Now Playing in Wave
                        if let current = playerVM.currentTrack, waveVM.isActive {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Сейчас звучит")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                
                                TrackRowView(track: current) {
                                    playerVM.showFullPlayer = true
                                }
                                .environmentObject(playerVM)
                                .environmentObject(libraryVM)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                                .padding(.horizontal, 18)
                            }
                        }
                        
                        // MARK: - Queue Preview
                        if !waveVM.waveTracks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Далее в потоке")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("Умный подбор")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.appAccentPink)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.appAccentPink.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                .padding(.horizontal, 18)
                                
                                LazyVStack(spacing: 5) {
                                    ForEach(Array(waveVM.waveTracks.prefix(8).enumerated()), id: \.element.id) { index, track in
                                        TrackRowView(track: track, trackNumber: index + 1) {
                                            playerVM.playQueue(tracks: waveVM.waveTracks, startIndex: index)
                                        }
                                        .environmentObject(playerVM)
                                        .environmentObject(libraryVM)
                                    }
                                }
                                .padding(.horizontal, 14)
                            }
                        }
                        
                        Spacer().frame(height: playerVM.currentTrack != nil ? 90 : 30)
                    }
                }
            }
            .navigationTitle("Моя Волна")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(timer) { _ in
                if playerVM.isPlaying && waveVM.isActive {
                    for i in 0..<barHeights.count {
                        barHeights[i] = CGFloat.random(in: 14...68)
                    }
                }
            }
        }
    }
    
    // MARK: - Ambient Background
    
    private var ambientBackground: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            Circle()
                .fill(Color.appAccentPink.opacity(0.16))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: -90, y: -130)
            
            Circle()
                .fill(Color.appAccentPurple.opacity(0.16))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: 110, y: 150)
        }
    }
}
