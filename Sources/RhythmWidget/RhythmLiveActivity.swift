import ActivityKit
import SwiftUI
import WidgetKit

@main
struct RhythmWidgetBundle: WidgetBundle {
    var body: some Widget {
        RhythmLiveActivity()
    }
}

struct RhythmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RhythmPlaybackAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.38, green: 0.84, blue: 0.69))
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.trackTitle)
                        .font(.headline)
                        .lineLimit(1)
                    Text(context.attributes.artist)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 0.38, green: 0.84, blue: 0.69))
            }
            .padding(16)
            .activityBackgroundTint(Color(red: 0.035, green: 0.045, blue: 0.055))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "waveform")
                        .foregroundStyle(Color(red: 0.38, green: 0.84, blue: 0.69))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundStyle(Color(red: 0.38, green: 0.84, blue: 0.69))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.attributes.trackTitle).font(.headline).lineLimit(1)
                        Text(context.attributes.artist).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: "waveform")
            } compactTrailing: {
                Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
            } minimal: {
                Image(systemName: "waveform")
            }
            .keylineTint(Color(red: 0.38, green: 0.84, blue: 0.69))
        }
    }
}
