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
    private let mint = Color(red: 0.38, green: 0.84, blue: 0.69)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RhythmPlaybackAttributes.self) { context in
            HStack(spacing: 13) {
                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(mint)
                    .frame(width: 44, height: 44)
                    .background(mint.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.trackTitle)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Text(context.attributes.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(mint)
                    .frame(width: 32, height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .activityBackgroundTint(Color(red: 0.035, green: 0.045, blue: 0.055))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "waveform")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(mint)
                        .frame(width: 30, height: 36)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(mint)
                        .frame(width: 30, height: 36)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(context.attributes.trackTitle)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                            Text(context.attributes.artist)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        HStack(spacing: 6) {
                            Capsule().fill(mint).frame(width: 24, height: 3)
                            Capsule().fill(mint.opacity(0.35)).frame(height: 3)
                            Text(context.state.isPlaying ? "ИГРАЕТ" : "ПАУЗА")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .tracking(0.8)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 3)
                }
            } compactLeading: {
                Image(systemName: "waveform")
                    .foregroundStyle(mint)
            } compactTrailing: {
                Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
                    .foregroundStyle(mint)
            } minimal: {
                Image(systemName: "waveform")
                    .foregroundStyle(mint)
            }
            .keylineTint(mint)
        }
    }
}
