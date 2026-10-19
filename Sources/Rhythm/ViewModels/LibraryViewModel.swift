import SwiftUI
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var savedTracks: [Track] = []
    
    private let library = LibraryService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        library.$savedTracks
            .receive(on: DispatchQueue.main)
            .assign(to: &$savedTracks)
    }
    
    func removeTrack(_ track: Track) {
        library.remove(track: track)
    }
    
    func isTrackSaved(_ track: Track) -> Bool {
        library.isTrackSaved(track)
    }
    
    func toggleSaved(track: Track) {
        library.toggleSaved(track: track)
    }
}
