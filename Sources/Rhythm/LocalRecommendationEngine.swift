import Foundation

enum LocalRecommendationEngine {
    static func rank(
        tracks: [Track],
        mood: String,
        likedIDs: Set<String>,
        recentIDs: [String],
        playCounts: [String: Int]
    ) -> [Track] {
        let likedTags = tracks.filter { likedIDs.contains($0.id) }.flatMap(\.tags)
        let historyTags = recentIDs.prefix(4)
            .compactMap { id in tracks.first { $0.id == id } }
            .flatMap(\.tags)

        var candidates = tracks.filter { !recentIDs.prefix(3).contains($0.id) }
        if candidates.isEmpty {
            candidates = tracks
        }

        return candidates
            .map { track -> (track: Track, score: Double) in
                var score = 0.0
                if mood != "Случайно", track.tags.contains(mood) { score += 4 }
                score += Double(likedTags.filter { track.tags.contains($0) }.count) * 1.7
                score += Double(historyTags.filter { track.tags.contains($0) }.count) * 0.35
                score -= Double(playCounts[track.id, default: 0]) * 0.4
                return (track, score)
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.track.id < $1.track.id
                }
                return $0.score > $1.score
            }
            .map(\.track)
    }
}
