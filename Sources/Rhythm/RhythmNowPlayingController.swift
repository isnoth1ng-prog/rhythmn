import Foundation
import MediaPlayer

@MainActor
enum RhythmNowPlayingController {
    private static var isConfigured = false
    private static var retainedTargets: [Any] = []

    static func configure(
        play: @escaping @MainActor () -> Void,
        pause: @escaping @MainActor () -> Void,
        toggle: @escaping @MainActor () -> Void,
        next: @escaping @MainActor () -> Void,
        previous: @escaping @MainActor () -> Void,
        seek: @escaping @MainActor (TimeInterval) -> Void
    ) {
        guard !isConfigured else { return }
        isConfigured = true

        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.isEnabled = false
        commands.pauseCommand.isEnabled = false
        commands.togglePlayPauseCommand.isEnabled = false
        commands.nextTrackCommand.isEnabled = false
        commands.previousTrackCommand.isEnabled = false
        commands.changePlaybackPositionCommand.isEnabled = false

        retainedTargets.append(commands.playCommand.addTarget { _ in
            Task { @MainActor in play() }
            return .success
        })
        retainedTargets.append(commands.pauseCommand.addTarget { _ in
            Task { @MainActor in pause() }
            return .success
        })
        retainedTargets.append(commands.togglePlayPauseCommand.addTarget { _ in
            Task { @MainActor in toggle() }
            return .success
        })
        retainedTargets.append(commands.nextTrackCommand.addTarget { _ in
            Task { @MainActor in next() }
            return .success
        })
        retainedTargets.append(commands.previousTrackCommand.addTarget { _ in
            Task { @MainActor in previous() }
            return .success
        })
        retainedTargets.append(commands.changePlaybackPositionCommand.addTarget { event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent,
                  event.positionTime.isFinite else {
                return .commandFailed
            }
            let position = event.positionTime
            Task { @MainActor in seek(position) }
            return .success
        })
    }

    static func update(
        track: Track?,
        playbackTime: TimeInterval,
        duration: TimeInterval,
        isPlaying: Bool
    ) {
        guard let track else {
            clear()
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: max(0, playbackTime),
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if duration.isFinite, duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }

        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = info
        center.playbackState = isPlaying ? .playing : .paused
        setCommandsEnabled(true)
    }

    static func clear() {
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = nil
        center.playbackState = .stopped
        setCommandsEnabled(false)
    }

    private static func setCommandsEnabled(_ enabled: Bool) {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.isEnabled = enabled
        commands.pauseCommand.isEnabled = enabled
        commands.togglePlayPauseCommand.isEnabled = enabled
        commands.nextTrackCommand.isEnabled = enabled
        commands.previousTrackCommand.isEnabled = enabled
        commands.changePlaybackPositionCommand.isEnabled = enabled
    }
}
