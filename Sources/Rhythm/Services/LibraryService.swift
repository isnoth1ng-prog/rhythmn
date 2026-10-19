import Foundation

class LibraryService: ObservableObject {
    static let shared = LibraryService()
    
    @Published var savedTracks: [Track] = []
    
    private let key = "vibeflow_saved_tracks"
    
    init() {
        load()
    }
    
    func save(track: Track) {
        guard !isTrackSaved(track) else { return }
        savedTracks.insert(track, at: 0)
        persist()
    }
    
    func remove(track: Track) {
        savedTracks.removeAll { $0.id == track.id }
        persist()
    }
    
    func isTrackSaved(_ track: Track) -> Bool {
        savedTracks.contains { $0.id == track.id }
    }
    
    func toggleSaved(track: Track) {
        if isTrackSaved(track) {
            remove(track: track)
        } else {
            save(track: track)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            let tracks = try JSONDecoder().decode([Track].self, from: data)
            savedTracks = tracks
        } catch {
            print("LibraryService load error: \(error)")
            savedTracks = []
        }
    }
    
    private func persist() {
        do {
            let data = try JSONEncoder().encode(savedTracks)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("LibraryService persist error: \(error)")
        }
    }
}
