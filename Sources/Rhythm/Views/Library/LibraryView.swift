import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.appBackground, Color.appBackgroundSecondary, Color(hex: "08080C")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if libraryVM.savedTracks.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Collection Hero Header
                            collectionHeroHeader
                                .padding(.horizontal, 18)
                                .padding(.top, 10)
                            
                            // Saved Tracks List
                            LazyVStack(spacing: 5) {
                                ForEach(Array(libraryVM.savedTracks.enumerated()), id: \.element.id) { index, track in
                                    TrackRowView(track: track, trackNumber: index + 1) {
                                        playerVM.playQueue(tracks: libraryVM.savedTracks, startIndex: index)
                                    }
                                    .environmentObject(playerVM)
                                    .environmentObject(libraryVM)
                                }
                            }
                            .padding(.horizontal, 14)
                            
                            Spacer().frame(height: playerVM.currentTrack != nil ? 90 : 30)
                        }
                    }
                }
            }
            .navigationTitle("Моя Библиотека")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Collection Hero Header
    
    private var collectionHeroHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(libraryVM.savedTracks.count) треков в коллекции")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.appTextSecondary)
                
                Text("Любимые треки")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                var tracks = libraryVM.savedTracks
                tracks.shuffle()
                playerVM.playQueue(tracks: tracks, startIndex: 0)
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14, weight: .bold))
                    Text("Микс")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.appAccentGradient)
                .clipShape(Capsule())
                .shadow(color: .appAccentPink.opacity(0.45), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.appAccentPink.opacity(0.12))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color.appAccentGradient)
            }
            
            Text("Пока нет любимых треков")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Нажимайте ❤️ в плеере или строках треков, чтобы добавлять музыку в свою персональную медиатеку")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
        }
        .padding(.top, 40)
    }
}
