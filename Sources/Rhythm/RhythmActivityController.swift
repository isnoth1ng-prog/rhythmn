import ActivityKit

enum RhythmActivityController {
    static func start(trackTitle: String, artist: String) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        await endAll()

        do {
            _ = try Activity.request(
                attributes: RhythmPlaybackAttributes(trackTitle: trackTitle, artist: artist),
                content: ActivityContent(
                    state: RhythmPlaybackAttributes.ContentState(isPlaying: true),
                    staleDate: nil
                ),
                pushType: nil
            )
        } catch {
            print("Live Activity could not start: \(error)")
        }
    }

    static func endAll() async {
        for activity in Activity<RhythmPlaybackAttributes>.activities {
            await activity.end(
                ActivityContent(
                    state: RhythmPlaybackAttributes.ContentState(isPlaying: false),
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
        }
    }
}
