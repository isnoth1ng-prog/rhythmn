import SwiftUI

struct WaveView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @StateObject private var waveVM = WaveViewModel()
    
    @State private var phase: CGFloat = 0
    @State private var waveAnimOffset: CGFloat = 0
    @State private var barHeights: [CGFloat] = [20, 45, 30, 60, 40, 75, 35, 55, 25, 65, 45, 30]
    
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Animated Ambient Wave Background
                ambientBackground
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        Spacer().frame(height: 20)
                        
                        // MARK: - Hero Wave Icon & Title
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [.appAccentPink.opacity(0.5), .appAccentPurple.opacity(0.2), .clear],
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 90
                                        )
                                    )
                                    .frame(width: 180, height: 180)
                                    .scaleEffect(waveVM.isActive ? 1.15 : 1.0)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: waveVM.isActive)
                                
                                Image(systemName: "waveform.circle.fill")
                                    .font(.system(size: 96))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.appAccentPink, .appAccentPurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .appAccentPink.opacity(0.6), radius: 20, x: 0, y: 10)
                            }
                            
                            Text("Моя Волна")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Бесконечный умный поток музыки, подбирающийся на ходу под ваш вкус")
                                .font(.system(size: 15))
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        // MARK: - Animated Audio Waveform Bars
                        HStack(spacing: 6) {
                            ForEach(0..<barHeights.count, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [.appAccentPink, .appAccentPurple],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: 4, height: playerVM.isPlaying && waveVM.isActive ? barHeights[index] : 8)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: barHeights[index])
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
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.appAccentGradient)
                            .clipShape(Capsule())
                            .shadow(color: .appAccentPink.opacity(0.5), radius: 15, x: 0, y: 6)
                        }
                        .padding(.horizontal, 32)
                        
                        // MARK: - Now Playing in Wave
                        if let current = playerVM.currentTrack, waveVM.isActive {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Сейчас звучит")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                
                                TrackRowView(track: current) {
                                    playerVM.showFullPlayer = true
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.appSurface.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // MARK: - Queue Preview
                        if !waveVM.waveTracks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Далее в потоке")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("Обновляется на лету")
                                        .font(.system(size: 12))
                                        .foregroundColor(.appAccentPink)
                                }
                                .padding(.horizontal, 16)
                                
                                LazyVStack(spacing: 4) {
                                    ForEach(Array(waveVM.waveTracks.prefix(8).enumerated()), id: \.element.id) { index, track in
                                        TrackRowView(track: track, trackNumber: index + 1) {
                                            playerVM.playQueue(tracks: waveVM.waveTracks, startIndex: index)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        Spacer().frame(height: playerVM.currentTrack != nil ? 90 : 30)
                    }
                }
            }
            .navigationTitle("Моя Волна")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onReceive(timer) { _ in
                if playerVM.isPlaying && waveVM.isActive {
                    for i in 0..<barHeights.count {
                        barHeights[i] = CGFloat.random(in: 12...70)
                    }
                }
            }
        }
    }
    
    // MARK: - Ambient Animated Background
    
    private var ambientBackground: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            // Glowing pulsing gradient circles
            Circle()
                .fill(Color.appAccentPink.opacity(0.18))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: -80, y: -120)
            
            Circle()
                .fill(Color.appAccentPurple.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: 100, y: 140)
        }
    }
}
