import SwiftUI

@MainActor
class ArtistViewModel: ObservableObject {
    @Published var artist: Artist?
    @Published var albums: [Album] = []
    @Published var topTracks: [Track] = []
    @Published var isLoading = false
    
    private let api = APIService.shared
    
    func loadArtist(id: String) async {
        isLoading = true
        do {
            async let a = api.getArtist(id: id)
            async let alb = api.getArtistAlbums(id: id)
            async let tracks = api.getArtistTopTracks(id: id)
            artist = try await a
            albums = try await alb
            topTracks = try await tracks
        } catch {
            print("Artist error: \(error)")
        }
        isLoading = false
    }
}
