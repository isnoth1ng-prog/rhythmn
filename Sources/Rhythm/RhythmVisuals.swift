import SwiftUI

enum RhythmPalette {
    static func background(_ light: Bool) -> Color {
        light ? Color(red: 0.95, green: 0.95, blue: 0.94) : Color(red: 0.035, green: 0.043, blue: 0.052)
    }

    static func surface(_ light: Bool) -> Color {
        light ? Color.white.opacity(0.82) : Color.white.opacity(0.065)
    }

    static func raised(_ light: Bool) -> Color {
        light ? Color(red: 0.90, green: 0.91, blue: 0.89) : Color.white.opacity(0.10)
    }

    static func text(_ light: Bool) -> Color {
        light ? Color(red: 0.10, green: 0.12, blue: 0.13) : Color(red: 0.95, green: 0.96, blue: 0.95)
    }

    static func muted(_ light: Bool) -> Color {
        text(light).opacity(0.56)
    }

    static func border(_ light: Bool) -> Color {
        text(light).opacity(light ? 0.10 : 0.11)
    }
}

extension ArtworkTone {
    var colors: [Color] {
        switch self {
        case .glacier:
            [Color(red: 0.18, green: 0.72, blue: 0.71), Color(red: 0.12, green: 0.23, blue: 0.48)]
        case .ember:
            [Color(red: 0.98, green: 0.42, blue: 0.28), Color(red: 0.36, green: 0.12, blue: 0.20)]
        case .orchid:
            [Color(red: 0.69, green: 0.44, blue: 0.88), Color(red: 0.24, green: 0.18, blue: 0.47)]
        case .moss:
            [Color(red: 0.43, green: 0.71, blue: 0.48), Color(red: 0.09, green: 0.27, blue: 0.25)]
        case .cobalt:
            [Color(red: 0.28, green: 0.57, blue: 0.93), Color(red: 0.12, green: 0.16, blue: 0.42)]
        case .amber:
            [Color(red: 0.98, green: 0.67, blue: 0.27), Color(red: 0.49, green: 0.25, blue: 0.11)]
        case .rose:
            [Color(red: 0.92, green: 0.43, blue: 0.56), Color(red: 0.36, green: 0.16, blue: 0.35)]
        case .graphite:
            [Color(red: 0.47, green: 0.56, blue: 0.63), Color(red: 0.12, green: 0.15, blue: 0.22)]
        }
    }
}

struct TrackArtwork: View {
    let track: Track
    var size: CGFloat
    var showsTitle = true

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                if let artworkURL = track.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        LinearGradient(colors: track.tone.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                } else {
                    LinearGradient(colors: track.tone.colors, startPoint: .topLeading, endPoint: .bottomTrailing)

                    Circle()
                        .stroke(.white.opacity(0.14), lineWidth: max(1, side * 0.004))
                        .frame(width: side * 0.82, height: side * 0.82)
                        .offset(x: side * 0.22, y: -side * 0.24)

                    Circle()
                        .fill(.white.opacity(0.10))
                        .frame(width: side * 0.48, height: side * 0.48)
                        .blur(radius: side * 0.05)
                        .offset(x: -side * 0.27, y: side * 0.29)

                    Image(systemName: "waveform")
                        .font(.system(size: side * 0.23, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.86))
                        .shadow(color: .black.opacity(0.18), radius: side * 0.04, y: side * 0.02)
                }

                if showsTitle {
                    VStack(alignment: .leading, spacing: side * 0.018) {
                        Spacer()
                        Text(track.artist.uppercased())
                            .font(.system(size: max(8, side * 0.035), weight: .bold, design: .monospaced))
                            .tracking(max(1, side * 0.006))
                            .lineLimit(1)
                        Text(track.title)
                            .font(.system(size: max(11, side * 0.075), weight: .semibold, design: .rounded))
                            .lineLimit(2)
                    }
                    .foregroundStyle(.white.opacity(0.94))
                    .padding(side * 0.085)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.54)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: max(14, side * 0.13), style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: max(14, side * 0.13), style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: track.tone.colors.last?.opacity(0.24) ?? .clear, radius: side * 0.09, y: side * 0.05)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(track.title), \(track.artist)")
    }
}

struct BrandMark: View {
    var size: CGFloat = 34
    var accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(accent.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                        .stroke(accent.opacity(0.34), lineWidth: 1)
                }
            Image(systemName: "waveform.path")
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundStyle(accent)
        }
        .frame(width: size, height: size)
    }
}

struct Eyebrow: View {
    let text: String
    var color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .tracking(2.1)
            .foregroundStyle(color)
    }
}

struct SectionHeading: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var light: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(RhythmPalette.text(light))
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RhythmPalette.muted(light))
                    .buttonStyle(.plain)
            }
        }
    }
}

struct SurfaceCard<Content: View>: View {
    var light: Bool
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(RhythmPalette.border(light), lineWidth: 1)
            }
    }
}
