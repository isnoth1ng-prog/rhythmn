import ActivityKit

struct RhythmPlaybackAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isPlaying: Bool
    }

    var trackTitle: String
    var artist: String
}
