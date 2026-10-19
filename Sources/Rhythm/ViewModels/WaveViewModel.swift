import SwiftUI

@MainActor
class WaveViewModel: ObservableObject {
    @Published var waveTracks: [Track] = []
    @Published var isLoading = false
    @Published var isActive = false
    
    private let api = APIService.shared
    private var listeningHistory: [String] = []
    
    func startWave(playerVM: PlayerViewModel) {
        isActive = true
        isLoading = true
        Task {
            do {
                let likedArtistIds = LibraryService.shared.savedTracks.compactMap {
                    $0.artistId.isEmpty ? nil : $0.artistId
                }
                let seedIds = listeningHistory.suffix(5).reversed().map { $0 }
                let tracks = try await api.getWaveNext(
                    history: listeningHistory,
                    likedArtistIds: Array(Set(likedArtistIds)),
                    seedTrackIds: seedIds,
                    count: 15
                )
                waveTracks = tracks
                if !tracks.isEmpty {
                    playerVM.playQueue(tracks: tracks, startIndex: 0)
                }
            } catch {
                print("Wave error: \(error)")
            }
            isLoading = false
        }
    }
    
    func loadMore() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                let tracks = try await api.getWaveNext(
                    history: listeningHistory,
                    likedArtistIds: [],
                    seedTrackIds: waveTracks.suffix(3).map { $0.id },
                    count: 10
                )
                waveTracks.append(contentsOf: tracks)
            } catch {
                print("Wave loadMore error: \(error)")
            }
            isLoading = false
        }
    }
    
    func addToHistory(trackId: String) {
        listeningHistory.append(trackId)
    }
}
