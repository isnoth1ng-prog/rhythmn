import SwiftUI

enum SearchType: String, CaseIterable {
    case tracks = "Треки"
    case artists = "Артисты"
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var trackResults: [Track] = []
    @Published var artistResults: [Artist] = []
    @Published var isSearching = false
    @Published var searchType: SearchType = .tracks
    
    private let api = APIService.shared
    private var searchTask: Task<Void, Never>?
    
    func search() {
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            trackResults = []
            artistResults = []
            return
        }
        
        searchTask = Task {
            // 0.5s debounce
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            
            isSearching = true
            do {
                switch searchType {
                case .tracks:
                    trackResults = try await api.searchTracks(query: query)
                case .artists:
                    artistResults = try await api.searchArtists(query: query)
                }
            } catch {
                if !Task.isCancelled {
                    print("Search error: \(error)")
                }
            }
            isSearching = false
        }
    }
}
