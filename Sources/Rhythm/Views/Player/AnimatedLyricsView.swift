import SwiftUI

struct AnimatedLyricsView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    
    var body: some View {
        ZStack {
            if let lyrics = playerVM.lyrics {
                if lyrics.isSynced, let lines = lyrics.lines, !lines.isEmpty {
                    syncedLyricsView(lines: lines)
                } else if let plainText = lyrics.plainText, !plainText.isEmpty {
                    plainLyricsView(text: plainText)
                } else {
                    noLyricsView
                }
            } else {
                loadingLyricsView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Apple Music Synced Lyrics
    
    private func syncedLyricsView(lines: [LyricsLine]) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 22) {
                    // Top spacing so first lines can be centered
                    Spacer().frame(height: 120)
                    
                    ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                        let isCurrent = (index == playerVM.currentLyricIndex)
                        let distance = abs(index - playerVM.currentLyricIndex)
                        
                        Text(line.text)
                            .font(.system(
                                size: fontSize(for: distance),
                                weight: isCurrent ? .bold : .semibold,
                                design: .rounded
                            ))
                            .foregroundColor(lineColor(for: distance))
                            .blur(radius: blurRadius(for: distance))
                            .scaleEffect(isCurrent ? 1.04 : 1.0)
                            .shadow(color: isCurrent ? .white.opacity(0.3) : .clear, radius: 8, x: 0, y: 0)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 28)
                            .id(line.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                playerVM.seek(to: line.time)
                            }
                            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: playerVM.currentLyricIndex)
                    }
                    
                    // Bottom spacing so last lines can be centered
                    Spacer().frame(height: 200)
                }
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black, location: 0.12),
                        .init(color: .black, location: 0.88),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onChange(of: playerVM.currentLyricIndex) { newIndex in
                if newIndex >= 0 && newIndex < lines.count {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(lines[newIndex].id, anchor: .center)
                    }
                }
            }
            .onAppear {
                if playerVM.currentLyricIndex < lines.count {
                    proxy.scrollTo(lines[playerVM.currentLyricIndex].id, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Plain Lyrics Fallback
    
    private func plainLyricsView(text: String) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text(text)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(8)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 40)
            }
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.08),
                    .init(color: .black, location: 0.92),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Empty State
    
    private var noLyricsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 44))
                .foregroundColor(.appTextSecondary)
            
            Text("Текст песни пока недоступен")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }
    
    // MARK: - Loading State
    
    private var loadingLyricsView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.appAccentPink)
                .scaleEffect(1.2)
            
            Text("Загрузка текста...")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
        }
    }
    
    // MARK: - Typography & Animation Helpers
    
    private func fontSize(for distance: Int) -> CGFloat {
        switch distance {
        case 0: return 26
        case 1: return 20
        case 2: return 18
        default: return 16
        }
    }
    
    private func lineColor(for distance: Int) -> Color {
        switch distance {
        case 0: return .white
        case 1: return .white.opacity(0.55)
        case 2: return .white.opacity(0.3)
        default: return .white.opacity(0.15)
        }
    }
    
    private func blurRadius(for distance: Int) -> CGFloat {
        switch distance {
        case 0, 1: return 0
        case 2: return 0.5
        default: return 1.2
        }
    }
}
