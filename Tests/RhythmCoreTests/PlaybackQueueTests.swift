import XCTest
@testable import RhythmCore

final class PlaybackQueueTests: XCTestCase {
    private var tracks: [Track] { DemoCatalog.tracks }

    func testSelectionStartsAtRequestedTrack() {
        var queue = PlaybackQueue()
        queue.select(tracks[2], from: tracks)

        XCTAssertEqual(queue.currentTrack?.id, tracks[2].id)
        XCTAssertEqual(queue.tracks.count, tracks.count)
    }

    func testNextAdvancesAndStopsAtEndWithoutRepeat() {
        var queue = PlaybackQueue()
        queue.select(tracks[tracks.count - 2], from: tracks)

        XCTAssertEqual(queue.advance(shuffling: false, repeatMode: .off)?.id, tracks[tracks.count - 1].id)
        XCTAssertNil(queue.advance(shuffling: false, repeatMode: .off))
    }

    func testRepeatAllWrapsToBeginning() {
        var queue = PlaybackQueue()
        queue.select(tracks[tracks.count - 1], from: tracks)

        XCTAssertEqual(queue.advance(shuffling: false, repeatMode: .all)?.id, tracks[0].id)
    }

    func testRepeatOneKeepsCurrentTrack() {
        var queue = PlaybackQueue()
        queue.select(tracks[1], from: tracks)

        XCTAssertEqual(queue.advance(shuffling: false, repeatMode: .one)?.id, tracks[1].id)
    }

    func testShuffleChoosesAnotherTrackFromQueue() {
        var queue = PlaybackQueue()
        queue.select(tracks[0], from: tracks)

        let next = queue.advance(shuffling: true, repeatMode: .off)

        XCTAssertNotNil(next)
        XCTAssertNotEqual(next?.id, tracks[0].id)
        XCTAssertTrue(tracks.dropFirst().contains { $0.id == next?.id })
    }

    func testPreviousRemainsAtFirstTrack() {
        var queue = PlaybackQueue()
        queue.select(tracks[0], from: tracks)

        XCTAssertEqual(queue.previous()?.id, tracks[0].id)
    }

    func testTrackDecodesLegacyStoredPayloadWithoutProviderFields() throws {
        let legacyJSON = """
        {
          "id": "legacy-track",
          "title": "Old title",
          "artist": "Old artist",
          "artistID": "old-artist",
          "album": "Old album",
          "duration": 180,
          "tags": ["Focus"],
          "tone": "glacier",
          "lyrics": [{"id": 0, "start": 0, "text": "Line"}]
        }
        """

        let track = try JSONDecoder().decode(Track.self, from: Data(legacyJSON.utf8))

        XCTAssertEqual(track.id, "legacy-track")
        XCTAssertNil(track.artworkURL)
        XCTAssertNil(track.audioPreviewURL)
        XCTAssertNil(track.localAudioURL)
        XCTAssertEqual(track.audioSource, .demo)
    }
}
