import Foundation

struct PlaybackQueue {
    private(set) var tracks: [Track] = []
    private(set) var currentIndex = 0

    var currentTrack: Track? {
        guard tracks.indices.contains(currentIndex) else { return nil }
        return tracks[currentIndex]
    }

    mutating func select(_ track: Track, from proposedTracks: [Track]? = nil) {
        if let proposedTracks, !proposedTracks.isEmpty {
            tracks = proposedTracks
            currentIndex = tracks.firstIndex(where: { $0.id == track.id }) ?? 0
        } else if let existingIndex = tracks.firstIndex(where: { $0.id == track.id }) {
            currentIndex = existingIndex
        } else {
            tracks = [track]
            currentIndex = 0
        }
    }

    mutating func previous() -> Track? {
        guard !tracks.isEmpty else { return nil }
        currentIndex = max(currentIndex - 1, 0)
        return currentTrack
    }

    mutating func advance(shuffling: Bool, repeatMode: RepeatMode) -> Track? {
        guard !tracks.isEmpty else { return nil }
        if repeatMode == .one {
            return currentTrack
        }

        if shuffling, tracks.count > 1 {
            let candidates = tracks.indices.filter { $0 != currentIndex }
            currentIndex = candidates.randomElement() ?? currentIndex
            return currentTrack
        }

        if currentIndex + 1 < tracks.count {
            currentIndex += 1
            return currentTrack
        }
        if repeatMode == .all {
            currentIndex = 0
            return currentTrack
        }
        return nil
    }
}
