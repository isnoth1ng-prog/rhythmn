import XCTest
@testable import RhythmCore

final class LocalRecommendationEngineTests: XCTestCase {
    private var tracks: [Track] { DemoCatalog.tracks }

    func testMoodMatchRanksAheadOfNonmatchingTracks() {
        let result = LocalRecommendationEngine.rank(
            tracks: tracks,
            mood: "Ночь",
            likedIDs: [],
            recentIDs: [],
            playCounts: [:]
        )

        XCTAssertTrue(result.first?.tags.contains("Ночь") == true)
    }

    func testLikedTagsImproveMatchingTracks() {
        let liked = tracks.first { $0.tags.contains("Инди") }!
        let result = LocalRecommendationEngine.rank(
            tracks: tracks,
            mood: "Случайно",
            likedIDs: [liked.id],
            recentIDs: [],
            playCounts: [:]
        )

        XCTAssertTrue(result.first?.tags.contains("Инди") == true)
    }

    func testRecentlyPlayedTracksAreDeferred() {
        let recentIDs = Array(tracks.prefix(3).map(\.id))
        let result = LocalRecommendationEngine.rank(
            tracks: tracks,
            mood: "Случайно",
            likedIDs: [],
            recentIDs: recentIDs,
            playCounts: [:]
        )

        XCTAssertFalse(result.prefix(3).contains { recentIDs.contains($0.id) })
    }

    func testAllRecentTracksRemainAvailableWhenThereAreNoAlternatives() {
        let recentIDs = tracks.map(\.id)
        let result = LocalRecommendationEngine.rank(
            tracks: Array(tracks.prefix(2)),
            mood: "Случайно",
            likedIDs: [],
            recentIDs: Array(tracks.prefix(2).map(\.id)),
            playCounts: [:]
        )

        XCTAssertEqual(Set(result.map(\.id)), Set(recentIDs.prefix(2)))
    }

    func testRankingIsDeterministicForSameInputs() {
        let inputs = (
            tracks: tracks,
            mood: "Фокус",
            likedIDs: Set([tracks[0].id]),
            recentIDs: [tracks[1].id],
            playCounts: [tracks[2].id: 2]
        )

        let first = LocalRecommendationEngine.rank(
            tracks: inputs.tracks,
            mood: inputs.mood,
            likedIDs: inputs.likedIDs,
            recentIDs: inputs.recentIDs,
            playCounts: inputs.playCounts
        )
        let second = LocalRecommendationEngine.rank(
            tracks: inputs.tracks,
            mood: inputs.mood,
            likedIDs: inputs.likedIDs,
            recentIDs: inputs.recentIDs,
            playCounts: inputs.playCounts
        )

        XCTAssertEqual(first.map(\.id), second.map(\.id))
    }
}
