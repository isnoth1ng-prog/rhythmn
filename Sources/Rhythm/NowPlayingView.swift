import SwiftUI

private struct ArtistRoute: Identifiable {
    let id: String
}

struct NowPlayingView: View {
    @ObservedObject var model: RhythmAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var lyricsVisible = true
    @State private var artistRoute: ArtistRoute?
    private var light: Bool { model.appearance == .light }

    var body: some View {
        Group {
            if let track = model.currentTrack {
                GeometryReader { geometry in
                    ZStack {
                        TrackArtwork(track: track, size: max(geometry.size.width, geometry.size.height) * 0.82, showsTitle: false)
                            .blur(radius: 72)
                            .opacity(light ? 0.18 : 0.27)
                            .scaleEffect(1.28)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        LinearGradient(
                            colors: [
                                RhythmPalette.background(light).opacity(0.72),
                                RhythmPalette.background(light).opacity(0.96),
                                RhythmPalette.background(light)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()

                        ScrollView {
                            VStack(spacing: 21) {
                                topBar

                                TrackArtwork(
                                    track: track,
                                    size: min(geometry.size.width - 80, max(218, geometry.size.height * 0.355)),
                                    showsTitle: false
                                )
                                .padding(.top, 3)

                                VStack(spacing: 6) {
                                    Text(track.title)
                                        .font(.system(size: 25, weight: .bold, design: .rounded))
                                        .tracking(-0.45)
                                        .foregroundStyle(RhythmPalette.text(light))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                    Button {
                                        artistRoute = ArtistRoute(id: track.artistID)
                                    } label: {
                                        HStack(spacing: 5) {
                                            Text(track.artist)
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 10, weight: .semibold))
                                        }
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(model.accent.color)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 16)

                                progressControl
                                    .padding(.horizontal, 2)

                                transportControls
                                    .padding(.horizontal, 6)

                                playerActions

                                if let notice = model.playbackNotice {
                                    HStack(alignment: .top, spacing: 9) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundStyle(model.accent.color)
                                        Text(notice)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(RhythmPalette.muted(light))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(13)
                                    .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 17))
                                }

                                lyricsPanel
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 25)
                            .frame(maxWidth: 560)
                            .frame(maxWidth: .infinity)
                        }
                        .scrollIndicators(.hidden)
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
                .sheet(item: $artistRoute) { route in
                    ArtistDiscographyView(model: model, artistID: route.id) { selectedTrack in
                        model.play(selectedTrack, in: model.tracks(for: selectedTrack.artistID))
                        artistRoute = nil
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(RhythmPalette.background(light))
                }
            } else {
                RhythmPalette.background(light).ignoresSafeArea()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RhythmPalette.text(light))
                    .frame(width: 42, height: 42)
                    .background(RhythmPalette.surface(light), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Свернуть плеер")

            Spacer()

            VStack(spacing: 3) {
                Eyebrow(
                    text: model.currentTrack?.audioSource == .appleMusicPreview
                        ? "APPLE MUSIC · ПРЕВЬЮ"
                        : (model.isPlaying ? "СЕЙЧАС ИГРАЕТ" : "ВЫБРАННЫЙ ТРЕК"),
                    color: model.accent.color
                )
                Text("RHYTHM PLAYER")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(RhythmPalette.muted(light))
            }

            Spacer()

            Button {
                lyricsVisible.toggle()
                if !lyricsVisible { dismiss() }
            } label: {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(lyricsVisible ? model.accent.color : RhythmPalette.muted(light))
                    .frame(width: 42, height: 42)
                    .background(RhythmPalette.surface(light), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(lyricsVisible ? "Скрыть текст песни" : "Показать текст песни")
        }
    }

    private var progressControl: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { model.currentTime },
                    set: { model.seek(to: $0) }
                ),
                in: 0...max(model.duration, 1)
            )
            .tint(model.accent.color)
            .disabled(model.duration <= 0)

            HStack {
                Text(model.formatTime(model.currentTime))
                Spacer()
                Text("-\(model.formatTime(max(model.duration - model.currentTime, 0)))")
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(RhythmPalette.muted(light))
        }
    }

    private var transportControls: some View {
        HStack(spacing: 0) {
            Button { model.cycleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(model.isShuffling ? model.accent.color : RhythmPalette.muted(light))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.isShuffling ? "Выключить перемешивание" : "Перемешать")

            Button { model.previousTrack() } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(RhythmPalette.text(light))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Предыдущий трек")

            Button { model.togglePlayback() } label: {
                ZStack {
                    Circle()
                        .fill(model.accent.color)
                        .frame(width: 66, height: 66)
                    if model.isLoading {
                        ProgressView()
                            .tint(Color.black.opacity(0.8))
                    } else {
                        Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 23, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.84))
                            .offset(x: model.isPlaying ? 0 : 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.isPlaying ? "Пауза" : "Воспроизвести")

            Button { model.nextTrack() } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(RhythmPalette.text(light))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Следующий трек")

            Button { model.cycleRepeatMode() } label: {
                Image(systemName: model.repeatMode.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(model.repeatMode == .off ? RhythmPalette.muted(light) : model.accent.color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Режим повтора: \(repeatLabel)")
        }
    }

    private var repeatLabel: String {
        switch model.repeatMode {
        case .off: "выключен"
        case .all: "вся очередь"
        case .one: "один трек"
        }
    }

    private var playerActions: some View {
        HStack {
            Button { if let track = model.currentTrack { model.toggleSaved(track) } } label: {
                Label(model.currentTrack.map { model.savedIDs.contains($0.id) } == true ? "В библиотеке" : "Сохранить", systemImage: model.currentTrack.map { model.savedIDs.contains($0.id) } == true ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(model.accent.color)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Button { if let track = model.currentTrack { model.toggleLiked(track) } } label: {
                Label(model.currentTrack.map { model.likedIDs.contains($0.id) } == true ? "Нравится" : "Нравится", systemImage: model.currentTrack.map { model.likedIDs.contains($0.id) } == true ? "heart.fill" : "heart")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(model.currentTrack.map { model.likedIDs.contains($0.id) } == true ? model.accent.color : RhythmPalette.muted(light))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var lyricsPanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Eyebrow(text: "ТЕКСТ ПЕСНИ", color: RhythmPalette.muted(light))
                Spacer()
                Text("СИНХРОНИЗАЦИЯ")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(RhythmPalette.muted(light).opacity(0.7))
            }

            if lyricsVisible {
                LyricFlow(model: model, light: light)
                    .frame(height: 190)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text("Текст скрыт")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(RhythmPalette.muted(light))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 78)
            }
        }
        .padding(17)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(RhythmPalette.border(light), lineWidth: 1))
        .animation(.easeInOut(duration: 0.25), value: lyricsVisible)
    }
}

private struct LyricFlow: View {
    @ObservedObject var model: RhythmAppModel
    let light: Bool

    private var activeLineID: Int? {
        model.currentLyrics.last(where: { $0.start <= model.currentTime })?.id
    }

    var body: some View {
        Group {
            if model.currentLyrics.isEmpty {
                Text("Текст появится вместе с подключённым источником.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(RhythmPalette.muted(light))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 13) {
                            ForEach(model.currentLyrics) { line in
                                let active = activeLineID == line.id
                                Text(line.text)
                                    .font(.system(size: active ? 22 : 17, weight: active ? .bold : .semibold, design: .rounded))
                                    .tracking(active ? -0.25 : -0.1)
                                    .foregroundStyle(active ? model.accent.color : RhythmPalette.text(light).opacity(0.36))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(line.id)
                                    .animation(.spring(response: 0.34, dampingFraction: 0.82), value: active)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: activeLineID) { _, newValue in
                        guard let newValue else { return }
                        withAnimation(.easeInOut(duration: 0.45)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                    .onAppear {
                        if let activeLineID {
                            proxy.scrollTo(activeLineID, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

struct ArtistDiscographyView: View {
    @ObservedObject var model: RhythmAppModel
    let artistID: String
    let onSelect: (Track) -> Void
    @Environment(\.dismiss) private var dismiss

    private var light: Bool { model.appearance == .light }
    private var artist: ArtistProfile? { model.artistProfile(id: artistID) }
    private var discography: [Track] { model.tracks(for: artistID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 21) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RhythmPalette.text(light))
                            .frame(width: 42, height: 42)
                            .background(RhythmPalette.surface(light), in: Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Eyebrow(text: "ИСПОЛНИТЕЛЬ", color: model.accent.color)
                    Spacer()
                    BrandMark(size: 34, accent: model.accent.color)
                }
                .padding(.top, 8)

                if let artist {
                    HStack(alignment: .center, spacing: 16) {
                        if let representative = discography.first {
                            TrackArtwork(track: representative, size: 104, showsTitle: false)
                                .clipShape(Circle())
                        }
                        VStack(alignment: .leading, spacing: 7) {
                            Text(artist.name)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .tracking(-0.8)
                                .foregroundStyle(RhythmPalette.text(light))
                            Text(artist.note)
                                .font(.system(size: 13))
                                .foregroundStyle(RhythmPalette.muted(light))
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(discography.count) ТРЕКА")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .tracking(1.8)
                                .foregroundStyle(model.accent.color)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(18)
                    .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 25))
                    .overlay(RoundedRectangle(cornerRadius: 25).stroke(RhythmPalette.border(light), lineWidth: 1))

                    SectionHeading(title: "Дискография", light: light)
                    ForEach(discography) { track in
                        TrackRow(model: model, track: track, onPlay: { onSelect(track) })
                    }
                } else {
                    EmptyPanel(title: "Исполнитель не найден", message: "Попробуй открыть его из поиска.", actionTitle: nil, action: nil, model: model)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}

struct PlaylistDetailView: View {
    @ObservedObject var model: RhythmAppModel
    let playlistID: String
    @Environment(\.dismiss) private var dismiss
    private var light: Bool { model.appearance == .light }
    private var playlist: RhythmPlaylist? { model.playlists.first { $0.id == playlistID } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RhythmPalette.text(light))
                            .frame(width: 42, height: 42)
                            .background(RhythmPalette.surface(light), in: Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Eyebrow(text: "ПЛЕЙЛИСТ", color: model.accent.color)
                    Spacer()
                    BrandMark(size: 34, accent: model.accent.color)
                }
                .padding(.top, 8)

                if let playlist {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(LinearGradient(colors: playlist.tone.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            Image(systemName: "waveform")
                                .font(.system(size: 34, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 96, height: 96)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(playlist.name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(RhythmPalette.text(light))
                            Text("\(model.tracks(in: playlist).count) треков")
                                .font(.system(size: 13))
                                .foregroundStyle(RhythmPalette.muted(light))
                        }
                        Spacer()
                    }
                    .padding(17)
                    .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 25))
                    .overlay(RoundedRectangle(cornerRadius: 25).stroke(RhythmPalette.border(light), lineWidth: 1))

                    SectionHeading(title: "Треки", light: light)
                    if model.tracks(in: playlist).isEmpty {
                        EmptyPanel(title: "Плейлист ждёт музыку", message: "Добавляй треки через меню с тремя точками в библиотеке или поиске.", actionTitle: nil, action: nil, model: model)
                    } else {
                        ForEach(model.tracks(in: playlist)) { track in
                            TrackRow(
                                model: model,
                                track: track,
                                onPlay: { model.play(track, in: model.tracks(in: playlist)) },
                                removeFromPlaylist: { model.remove(track, from: playlist.id) }
                            )
                        }
                    }
                } else {
                    EmptyPanel(title: "Плейлист не найден", message: "Он мог быть удалён.", actionTitle: nil, action: nil, model: model)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}
