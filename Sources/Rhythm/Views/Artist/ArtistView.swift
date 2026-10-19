import SwiftUI

struct ArtistView: View {
    let artistId: String
    @EnvironmentObject var playerVM: PlayerViewModel
    @StateObject private var viewModel = ArtistViewModel()
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if let artist = viewModel.artist {
                    ArtistHeaderView(artist: artist)
                } else if viewModel.isLoading {
                    ZStack {
                        Color.appSurface
                        ProgressView()
                            .tint(.appAccentPink)
                    }
                    .frame(height: 300)
                }
                
                // MARK: - Popular Tracks
                if !viewModel.topTracks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Популярные треки")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                        
                        LazyVStack(spacing: 4) {
                            ForEach(Array(viewModel.topTracks.enumerated()), id: \.element.id) { index, track in
                                TrackRowView(track: track, trackNumber: index + 1) {
                                    playerVM.playQueue(tracks: viewModel.topTracks, startIndex: index)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // MARK: - Discography / Albums
                if !viewModel.albums.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Дискография")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.albums) { album in
                                AlbumCardView(album: album) {
                                    // If album has tracks, play them; otherwise could load
                                    if let tracks = album.tracks, !tracks.isEmpty {
                                        playerVM.playQueue(tracks: tracks, startIndex: 0)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, playerVM.currentTrack != nil ? 90 : 24)
        }
        .background(
            LinearGradient(
                colors: [.appBackground, .appBackgroundSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadArtist(id: artistId)
        }
        .refreshable {
            await viewModel.loadArtist(id: artistId)
        }
    }
}
