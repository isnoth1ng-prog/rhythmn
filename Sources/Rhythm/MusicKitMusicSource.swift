import Foundation
import MusicKit

struct MusicKitMusicSource: MusicSource {
    func loadCatalog() async throws -> [Track] {
        // Keep the app usable before the user grants catalog access.
        DemoCatalog.tracks
    }

    func searchCatalog(_ query: String) async throws -> [Track] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return [] }

        let status: MusicAuthorization.Status
        if MusicAuthorization.currentStatus == .authorized {
            status = .authorized
        } else {
            status = await MusicAuthorization.request()
        }
        guard status == .authorized else {
            throw MusicKitMusicSourceError.authorizationRequired
        }

        var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
        request.limit = 25
        let response = try await request.response()
        return response.songs.map(makeTrack)
    }

    func audioURL(for track: Track) async throws -> URL? {
        track.audioPreviewURL
    }

    func lyrics(for track: Track) async throws -> [LyricLine]? {
        track.lyrics.isEmpty ? nil : track.lyrics
    }

    private func makeTrack(_ song: Song) -> Track {
        let songID = song.id.rawValue
        let artistID = song.artists?.first?.id.rawValue ?? Self.artistID(for: song.artistName)
        let previewURL = song.previewAssets?.first(where: { $0.url != nil })?.url
        return Track(
            id: "apple-music:\(songID)",
            title: song.title,
            artist: song.artistName,
            artistID: artistID,
            album: song.albumTitle ?? "Apple Music",
            duration: song.duration ?? 0,
            tags: song.genreNames,
            tone: .glacier,
            lyrics: [],
            artworkURL: song.artwork?.url(width: 600, height: 600),
            audioPreviewURL: previewURL,
            audioSource: .appleMusicPreview
        )
    }

    private static func artistID(for name: String) -> String {
        let folded = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let slug = folded
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if !slug.isEmpty { return slug }
        let codepoints = name.unicodeScalars.map { String($0.value, radix: 16) }.joined(separator: "-")
        return "artist-\(codepoints)"
    }
}

enum MusicKitMusicSourceError: LocalizedError {
    case authorizationRequired

    var errorDescription: String? {
        switch self {
        case .authorizationRequired:
            "Разреши Rhythm доступ к Apple Music, чтобы искать в каталоге."
        }
    }
}
