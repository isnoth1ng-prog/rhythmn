import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.appBackground, .appBackgroundSecondary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if libraryVM.savedTracks.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header Stats & Shuffle All Button
                            HStack {
                                Text("\(libraryVM.savedTracks.count) треков")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                                
                                Spacer()
                                
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    var tracks = libraryVM.savedTracks
                                    tracks.shuffle()
                                    playerVM.playQueue(tracks: tracks, startIndex: 0)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "shuffle")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Перемешать")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.appAccentGradient)
                                    .clipShape(Capsule())
                                    .shadow(color: .appAccentPink.opacity(0.4), radius: 8, x: 0, y: 3)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            
                            // Saved Tracks List
                            LazyVStack(spacing: 4) {
                                ForEach(Array(libraryVM.savedTracks.enumerated()), id: \.element.id) { index, track in
                                    TrackRowView(track: track, trackNumber: index + 1) {
                                        playerVM.playQueue(tracks: libraryVM.savedTracks, startIndex: index)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, playerVM.currentTrack != nil ? 90 : 24)
                    }
                }
            }
            .navigationTitle("Моя Библиотека")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appAccentPink.opacity(0.8), .appAccentPurple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Нет сохранённых треков")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Сохраняйте любимые треки, нажимая ❤️ в плеере или через меню трека")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
