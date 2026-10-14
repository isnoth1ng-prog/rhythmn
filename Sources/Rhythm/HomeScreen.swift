struct HomeScreen: View {
    @ObservedObject var model: RhythmAppModel
    let openPlayer: () -> Void
    let openSearch: () -> Void
    let openWave: () -> Void

    private var light: Bool { model.appearance == .light }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack(spacing: 9) {
                        BrandMark(size: 31, accent: model.accent.color)
                        Text("RHYTHM")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .tracking(3.2)
                            .foregroundStyle(RhythmPalette.text(light))
                        Spacer()
                        Eyebrow(text: "ТВОЙ РИТМ", color: model.accent.color)
                    }

                    Text("Музыка для твоего дня")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .tracking(-1)
                        .foregroundStyle(RhythmPalette.text(light))
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: openSearch) {
                        HStack(spacing: 11) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Найти трек, артиста или альбом")
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(RhythmPalette.muted(light))
                        .padding(.horizontal, 15)
                        .frame(height: 52)
                        .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 17))
                        .overlay(RoundedRectangle(cornerRadius: 17).stroke(RhythmPalette.border(light), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 18)

                if let track = model.currentTrack ?? model.recentlyPlayed.first {
                    VStack(alignment: .leading, spacing: 12) {
                        homeSectionTitle("Продолжить")
                        Button {
                            if model.currentTrack?.id == track.id {
                                openPlayer()
                            } else {
                                model.play(track, in: model.recentlyPlayed)
                                openPlayer()
                            }
                        } label: {
                            HStack(spacing: 13) {
                                TrackArtwork(track: track, size: 62, showsTitle: false)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(track.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(RhythmPalette.text(light))
                                        .lineLimit(1)
                                    Text(track.artist)
                                        .font(.system(size: 12))
                                        .foregroundStyle(RhythmPalette.muted(light))
                                        .lineLimit(1)
                                    Text(track.audioSource == .appleMusicPreview ? "APPLE MUSIC · ПРЕВЬЮ" : "ТВОЯ КОЛЛЕКЦИЯ")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .tracking(1.1)
                                        .foregroundStyle(model.accent.color)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.black.opacity(0.82))
                                    .frame(width: 42, height: 42)
                                    .background(model.accent.color, in: Circle())
                            }
                            .padding(13)
                            .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(RhythmPalette.border(light), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button(action: openSearch) {
                        HStack(spacing: 13) {
                            Image(systemName: "waveform")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(model.accent.color)
                                .frame(width: 50, height: 50)
                                .background(model.accent.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Начни с поиска музыки")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(RhythmPalette.text(light))
                                Text("Открой каталог или демо-коллекцию.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(RhythmPalette.muted(light))
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundStyle(model.accent.color)
                        }
                        .padding(14)
                        .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(RhythmPalette.border(light), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                homeTrackSection(
                    title: "Недавно слушали",
                    tracks: model.recentlyPlayed,
                    emptyMessage: "Здесь появятся треки после первого прослушивания."
                )

                homeTrackSection(
                    title: "Любимое",
                    tracks: model.likedTracks,
                    emptyMessage: "Ставь лайк трекам, чтобы быстро находить их здесь."
                )

                Button(action: openWave) {
                    HStack(spacing: 14) {
                        Image(systemName: "waveform.path")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.82))
                            .frame(width: 50, height: 50)
                            .background(model.accent.color, in: RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Моя волна")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(RhythmPalette.text(light))
                            Text("Подборка из твоей истории, лайков и настроения.")
                                .font(.system(size: 12))
                                .foregroundStyle(RhythmPalette.muted(light))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(model.accent.color)
                    }
                    .padding(15)
                    .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(RhythmPalette.border(light), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 25)
        }
        .scrollIndicators(.hidden)
    }

    private func homeSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .tracking(-0.35)
            .foregroundStyle(RhythmPalette.text(light))
    }

    @ViewBuilder
    private func homeTrackSection(title: String, tracks: [Track], emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            homeSectionTitle(title)
            if tracks.isEmpty {
                Text(emptyMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(RhythmPalette.muted(light))
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(RhythmPalette.border(light), lineWidth: 1))
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 13) {
                        ForEach(tracks.prefix(12)) { track in
                            Button {
                                model.play(track, in: tracks)
                                openPlayer()
                            } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    TrackArtwork(track: track, size: 142, showsTitle: false)
                                    Text(track.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(RhythmPalette.text(light))
                                        .lineLimit(1)
                                    Text(track.artist)
                                        .font(.system(size: 11))
                                        .foregroundStyle(RhythmPalette.muted(light))
                                        .lineLimit(1)
                                }
                                .frame(width: 142, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

