import Foundation

/// Replace this adapter when connecting a real catalog, streaming provider, and lyrics service.
protocol MusicSource {
    func loadCatalog() async throws -> [Track]
    func audioURL(for track: Track) async throws -> URL?
    func lyrics(for track: Track) async throws -> [LyricLine]?
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
