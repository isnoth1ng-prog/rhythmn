import Foundation

/// Protocol shared by the local fallback and configured catalog providers.
protocol MusicSource {
    func loadCatalog() async throws -> [Track]
    func searchCatalog(_ query: String) async throws -> [Track]
    func audioURL(for track: Track) async throws -> URL?
    func lyrics(for track: Track) async throws -> [LyricLine]?
}

extension MusicSource {
    func searchCatalog(_ query: String) async throws -> [Track] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        return try await loadCatalog().filter {
            [$0.title, $0.artist, $0.album, $0.tags.joined(separator: " ")]
                .contains { $0.localizedCaseInsensitiveContains(needle) }
        }
    }
}

/// Local UI fixture. It deliberately contains no remote audio or artwork URLs.
struct DemoMusicSource: MusicSource {
    func loadCatalog() async throws -> [Track] {
        DemoCatalog.tracks
    }

    func audioURL(for track: Track) async throws -> URL? {
        nil
    }

    func lyrics(for track: Track) async throws -> [LyricLine]? {
        track.lyrics
    }
}
