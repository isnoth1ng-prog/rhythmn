import SwiftUI

private enum RootSheet: Identifiable {
    case player
    case artist(String)
    case playlist(String)

    var id: String {
        switch self {
        case .player: "player"
        case .artist(let id): "artist-\(id)"
        case .playlist(let id): "playlist-\(id)"
        }
    }
}

struct ContentView: View {
    @StateObject private var model = RhythmAppModel()
    @State private var selectedTab: RhythmTab = .library
    @State private var activeSheet: RootSheet?

    private var light: Bool { model.appearance == .light }

    var body: some View {
        ZStack {
            RhythmPalette.background(light).ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .library:
                        LibraryScreen(model: model, openPlayer: { activeSheet = .player }, openPlaylist: { activeSheet = .playlist($0) }, openSearch: { selectedTab = .search })
                    case .search:
                        SearchScreen(model: model, openPlayer: { activeSheet = .player }, openArtist: { activeSheet = .artist($0) })
                    case .wave:
                        WaveScreen(model: model, openPlayer: { activeSheet = .player })
                    case .settings:
                        SettingsScreen(model: model)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let track = model.currentTrack {
                    MiniPlayer(
                        model: model,
                        track: track,
                        openPlayer: { activeSheet = .player }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                BottomNavigation(selectedTab: $selectedTab, model: model)
            }
        }
        .preferredColorScheme(model.appearance.preferredColorScheme)
        .animation(.spring(response: 0.36, dampingFraction: 0.86), value: model.currentTrack?.id)
        .sheet(item: $activeSheet) { route in
            switch route {
            case .player:
                if model.currentTrack != nil {
                    NowPlayingView(model: model)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.hidden)
                        .presentationBackground(RhythmPalette.background(light))
                }
            case .artist(let id):
                ArtistDiscographyView(model: model, artistID: id) { track in
                    model.play(track, in: model.tracks(for: id))
                    activeSheet = .player
                }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(RhythmPalette.background(light))
            case .playlist(let id):
                PlaylistDetailView(model: model, playlistID: id)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(RhythmPalette.background(light))
            }
        }
        .task {
            // Playback is not restored across launches, so clear any stale Dynamic Island activity.
            await RhythmActivityController.endAll()
        }
    }
}

private struct ScreenIntro: View {
    let model: RhythmAppModel
    let eyebrow: String
    let title: String
    let subtitle: String

    private var light: Bool { model.appearance == .light }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 9) {
                BrandMark(size: 31, accent: model.accent.color)
                Text("RHYTHM")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .tracking(3.2)
                    .foregroundStyle(RhythmPalette.text(light))
                Spacer()
                Eyebrow(text: eyebrow, color: model.accent.color)
            }
            .padding(.bottom, 8)

            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-1.1)
                .foregroundStyle(RhythmPalette.text(light))
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(RhythmPalette.muted(light))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 18)
    }
}

private struct LibraryScreen: View {
    @ObservedObject var model: RhythmAppModel
    let openPlayer: () -> Void
    let openPlaylist: (String) -> Void
    let openSearch: () -> Void
    @State private var showingPlaylistPrompt = false
    @State private var playlistName = ""

    private var light: Bool { model.appearance == .light }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 27) {
                ScreenIntro(
                    model: model,
                    eyebrow: "ТВОЯ КОЛЛЕКЦИЯ",
                    title: "Моя музыка",
                    subtitle: "Треки, к которым хочется вернуться."
                )

                libraryHero

                HStack(spacing: 12) {
                    SummaryTile(title: "Сохранено", value: "\(model.savedTracks.count)", symbol: "bookmark.fill", model: model)
                    SummaryTile(title: "Нравится", value: "\(model.likedTracks.count)", symbol: "heart.fill", model: model)
                }

                VStack(alignment: .leading, spacing: 13) {
                    SectionHeading(title: "Плейлисты", actionTitle: "Создать", action: { showingPlaylistPrompt = true }, light: light)
                    if model.playlists.isEmpty {
                        Button { showingPlaylistPrompt = true } label: {
                            HStack(spacing: 13) {
                                Image(systemName: "plus")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(model.accent.color)
                                    .frame(width: 48, height: 48)
                                    .background(model.accent.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 16))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Собери свою подборку")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(RhythmPalette.text(light))
                                    Text("Создай плейлист и добавляй туда треки")
                                        .font(.system(size: 12))
                                        .foregroundStyle(RhythmPalette.muted(light))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 21))
                            .overlay(RoundedRectangle(cornerRadius: 21).stroke(RhythmPalette.border(light), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(model.playlists) { playlist in
                                    Button { openPlaylist(playlist.id) } label: {
                                        PlaylistCard(playlist: playlist, count: model.tracks(in: playlist).count, light: light)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Button { showingPlaylistPrompt = true } label: {
                                    VStack(spacing: 10) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(model.accent.color)
                                        Text("Новый")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(RhythmPalette.muted(light))
                                    }
                                    .frame(width: 112, height: 126)
                                    .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 22))
                                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(RhythmPalette.border(light), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                trackSection(
                    title: "Сохранённое",
                    subtitle: "Твоя личная библиотека",
                    tracks: model.savedTracks,
                    emptyTitle: "Здесь пока тихо",
                    emptyText: "Ищи треки в каталоге Apple Music или слушай локальную демо-коллекцию.",
                    emptyAction: openSearch,
                    emptyActionTitle: "Открыть поиск",
                    queue: model.savedTracks
                )

                trackSection(
                    title: "Недавно слушал",
                    subtitle: nil,
                    tracks: model.recentlyPlayed,
                    emptyTitle: "История появится здесь",
                    emptyText: "Выбранные треки будут собраны в одном месте.",
                    emptyAction: nil,
                    emptyActionTitle: nil,
                    queue: model.recentlyPlayed
                )

                trackSection(
                    title: "Демо-каталог",
                    subtitle: "Интерфейсная подборка для проверки приложения",
                    tracks: model.tracks,
                    emptyTitle: "Каталог пуст",
                    emptyText: "Добавленный источник появится здесь.",
                    emptyAction: nil,
                    emptyActionTitle: nil,
                    queue: model.tracks
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .scrollIndicators(.hidden)
        .alert("Новый плейлист", isPresented: $showingPlaylistPrompt) {
            TextField("Название", text: $playlistName)
            Button("Создать") {
                model.createPlaylist(playlistName)
                playlistName = ""
            }
            Button("Отмена", role: .cancel) { playlistName = "" }
        } message: {
            Text("Подборка сохранится на этом устройстве.")
        }
    }

    private var libraryHero: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [model.accent.color.opacity(light ? 0.20 : 0.34), Color(red: 0.16, green: 0.25, blue: 0.28).opacity(light ? 0.16 : 0.7), RhythmPalette.surface(light)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .stroke(model.accent.color.opacity(0.25), lineWidth: 1)
                .frame(width: 178, height: 178)
                .offset(x: 242, y: -52)
            Circle()
                .stroke(model.accent.color.opacity(0.15), lineWidth: 1)
                .frame(width: 128, height: 128)
                .offset(x: 275, y: -21)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 11) {
                    Eyebrow(text: "СЛУШАЙ ПО-СВОЕМУ", color: model.accent.color)
                    Text("Твой звук.\nТвои правила.")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .tracking(-0.5)
                        .foregroundStyle(RhythmPalette.text(light))
                    Button(action: openSearch) {
                        HStack(spacing: 7) {
                            Text("Найти музыку")
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(model.accent.color)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
                Image(systemName: "waveform.path")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(model.accent.color.opacity(0.85))
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
            }
            .padding(21)
        }
        .frame(height: 184)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(RhythmPalette.border(light), lineWidth: 1))
    }

    @ViewBuilder
    private func trackSection(
        title: String,
        subtitle: String?,
        tracks: [Track],
        emptyTitle: String,
        emptyText: String,
        emptyAction: (() -> Void)?,
        emptyActionTitle: String?,
        queue: [Track]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: title, light: light)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(RhythmPalette.muted(light))
                    .padding(.top, -7)
            }
            if tracks.isEmpty {
                EmptyPanel(title: emptyTitle, message: emptyText, actionTitle: emptyActionTitle, action: emptyAction, model: model)
            } else {
                VStack(spacing: 5) {
                    ForEach(tracks) { track in
                        TrackRow(model: model, track: track, onPlay: {
                            model.play(track, in: queue)
                            openPlayer()
                        })
                    }
                }
            }
        }
    }
}

private struct SearchScreen: View {
    @ObservedObject var model: RhythmAppModel
    let openPlayer: () -> Void
    let openArtist: (String) -> Void
    @State private var query = ""
    @State private var filter: SearchFilter = .all

    private var light: Bool { model.appearance == .light }
    private var filteredTracks: [Track] {
        let results = model.didSearchCatalog && !model.catalogSearchResults.isEmpty
            ? model.catalogSearchResults
            : model.searchTracks(query)
        switch filter {
        case .all, .tracks:
            return results
        case .artists:
            guard !query.isEmpty else { return [] }
            let matchingArtistIDs = Set(model.searchArtists(query).map(\.id))
            return results.filter { matchingArtistIDs.contains($0.artistID) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenIntro(model: model, eyebrow: "ПОИСК", title: "Найди свой ритм", subtitle: "Ищи по треку, исполнителю или альбому.")

                HStack(spacing: 11) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(model.accent.color)
                    TextField("Что включить?", text: $query)
                        .font(.system(size: 16))
                        .foregroundStyle(RhythmPalette.text(light))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(RhythmPalette.muted(light))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(RhythmPalette.surface(light), in: Capsule())
                .overlay(Capsule().stroke(RhythmPalette.border(light), lineWidth: 1))

                HStack(spacing: 8) {
                    ForEach(SearchFilter.allCases) { option in
                        Button { filter = option } label: {
                            Text(option.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(filter == option ? RhythmPalette.background(light) : RhythmPalette.muted(light))
                                .padding(.horizontal, 15)
                                .padding(.vertical, 9)
                                .background(filter == option ? model.accent.color : RhythmPalette.surface(light), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if query.isEmpty {
                    VStack(alignment: .leading, spacing: 13) {
                        SectionHeading(title: "Под настроение", light: light)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(["Ночь", "Спокойствие", "Энергия", "Фокус"], id: \.self) { tag in
                                Button {
                                    query = tag
                                    filter = .tracks
                                } label: {
                                    HStack {
                                        Text(tag)
                                            .font(.system(size: 14, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundStyle(RhythmPalette.text(light))
                                    .padding(15)
                                    .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 18))
                                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(RhythmPalette.border(light), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    let artists = model.searchArtists(query)
                    if filter != .tracks && !artists.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeading(title: "Исполнители", light: light)
                            ForEach(artists) { artist in
                                Button { openArtist(artist.id) } label: {
                                    HStack(spacing: 12) {
                                        TrackArtwork(track: model.tracks.first(where: { $0.artistID == artist.id }) ?? model.tracks[0], size: 48, showsTitle: false)
                                            .clipShape(Circle())
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(artist.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(RhythmPalette.text(light))
                                            Text(artist.note)
                                                .font(.system(size: 12))
                                                .foregroundStyle(RhythmPalette.muted(light))
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(RhythmPalette.muted(light))
                                    }
                                    .padding(12)
                                    .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 19))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if model.isSearchingCatalog {
                        HStack(spacing: 9) {
                            ProgressView().tint(model.accent.color)
                            Text("Ищем в Apple Music")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(RhythmPalette.muted(light))
                        }
                        .padding(.vertical, 4)
                    }
                    if let message = model.catalogSearchMessage {
                        Text(message)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(RhythmPalette.muted(light))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 15))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: model.didSearchCatalog && !model.catalogSearchResults.isEmpty ? "Apple Music" : "Треки", light: light)
                        if filteredTracks.isEmpty {
                            EmptyPanel(title: "Ничего не найдено", message: "Попробуй другое название или исполнителя.", actionTitle: nil, action: nil, model: model)
                        } else {
                            ForEach(filteredTracks) { track in
                                TrackRow(model: model, track: track, onPlay: {
                                    model.play(track, in: filteredTracks)
                                    openPlayer()
                                })
                            }
                        }
                    }
                }

                if query.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "Сейчас в каталоге", light: light)
                        ForEach(model.tracks.prefix(4)) { track in
                            TrackRow(model: model, track: track, onPlay: {
                                model.play(track, in: model.tracks)
                                openPlayer()
                            })
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .task(id: query) {
            let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty else {
                model.clearCatalogSearch()
                return
            }
            do {
                try await Task.sleep(for: .milliseconds(350))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await model.searchCatalog(term)
        }
    }
}

private enum SearchFilter: String, CaseIterable, Identifiable {
    case all, tracks, artists
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "Всё"
        case .tracks: "Треки"
        case .artists: "Артисты"
        }
    }
}

private struct WaveScreen: View {
    @ObservedObject var model: RhythmAppModel
    let openPlayer: () -> Void
    private let moods = ["Случайно", "Ночь", "Спокойствие", "Энергия", "Фокус"]
    private var light: Bool { model.appearance == .light }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 23) {
                ScreenIntro(model: model, eyebrow: "ПОД ТВОЁ НАСТРОЕНИЕ", title: "Моя волна", subtitle: "Подборка меняется от твоих отметок и прослушиваний.")

                waveHero

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(moods, id: \.self) { mood in
                            Button {
                                model.waveMood = mood
                                model.refreshWave()
                            } label: {
                                Text(mood)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(model.waveMood == mood ? RhythmPalette.background(light) : RhythmPalette.muted(light))
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 9)
                                    .background(model.waveMood == mood ? model.accent.color : RhythmPalette.surface(light), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 5) {
                        SectionHeading(title: "Следом для тебя", light: light)
                        Text("Порядок собирается заново с учётом лайков и истории.")
                            .font(.system(size: 12))
                            .foregroundStyle(RhythmPalette.muted(light))
                    }
                    Spacer(minLength: 4)
                    Button { model.refreshWave() } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(model.accent.color)
                            .frame(width: 40, height: 40)
                            .background(model.accent.color.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Собрать новую волну")
                }

                VStack(spacing: 5) {
                    ForEach(model.waveQueue.indices, id: \.self) { index in
                        let track = model.waveQueue[index]
                        TrackRow(model: model, track: track, onPlay: {
                            model.playFromWave(track)
                            openPlayer()
                        }, position: index + 1)
                    }
                }

                Text("Рекомендации учитывают настроение, лайки и историю в локальной библиотеке. Поиск в каталоге Apple Music доступен отдельно.")
                    .font(.system(size: 11))
                    .foregroundStyle(RhythmPalette.muted(light))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            if model.waveQueue.isEmpty { model.refreshWave() }
        }
    }

    private var waveHero: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [model.accent.color.opacity(light ? 0.28 : 0.34), Color(red: 0.18, green: 0.22, blue: 0.33), RhythmPalette.surface(light)], startPoint: .topLeading, endPoint: .bottomTrailing))
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "RHYTHM RADIO", color: model.accent.color)
                    Text("Продолжай\nсвою волну")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .tracking(-0.6)
                        .foregroundStyle(.white)
                    Text("\(model.waveQueue.count) треков · \(model.waveMood.lowercased())")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.68))
                    Button {
                        model.refreshWave()
                        if let first = model.waveQueue.first {
                            model.playFromWave(first)
                            openPlayer()
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Слушать волну")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 0.04, green: 0.06, blue: 0.07))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(model.accent.color, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
                WaveformGlyph(accent: model.accent.color)
                    .frame(width: 72, height: 84)
            }
            .padding(21)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

private struct WaveformGlyph: View {
    let accent: Color
    private let heights: [CGFloat] = [16, 30, 50, 36, 66, 43, 26, 58, 34, 20]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(heights.indices, id: \.self) { index in
                let height = heights[index]
                Capsule()
                    .fill(accent.opacity(index.isMultiple(of: 3) ? 1 : 0.62))
                    .frame(width: 4, height: height)
            }
        }
        .shadow(color: accent.opacity(0.24), radius: 14)
        .accessibilityHidden(true)
    }
}

private struct SettingsScreen: View {
    @ObservedObject var model: RhythmAppModel
    private var light: Bool { model.appearance == .light }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 27) {
                ScreenIntro(model: model, eyebrow: "ПОД ТЕБЯ", title: "Настройки", subtitle: "Собери интерфейс, который ощущается твоим.")

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeading(title: "Оформление", light: light)
                    HStack(spacing: 9) {
                        ForEach(AppAppearance.allCases) { option in
                            Button { model.appearance = option } label: {
                                VStack(spacing: 9) {
                                    Image(systemName: appearanceSymbol(option))
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(model.appearance == option ? model.accent.color : RhythmPalette.muted(light))
                                    Text(option.title)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(RhythmPalette.text(light))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 78)
                                .background(model.appearance == option ? model.accent.color.opacity(0.12) : RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(model.appearance == option ? model.accent.color.opacity(0.48) : RhythmPalette.border(light), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeading(title: "Акцент", light: light)
                    SurfaceCard(light: light) {
                        HStack(spacing: 0) {
                            ForEach(AccentTone.allCases) { tone in
                                Button { model.accent = tone } label: {
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(tone.color.gradient)
                                            .frame(width: 34, height: 34)
                                            .overlay {
                                                if model.accent == tone {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundStyle(Color.black.opacity(0.75))
                                                }
                                            }
                                            .overlay(Circle().stroke(.white.opacity(0.24), lineWidth: 1))
                                        Text(tone.title)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(RhythmPalette.muted(light))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Музыкальный источник", light: light)
                    SurfaceCard(light: light) {
                        HStack(spacing: 13) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(model.accent.color)
                                .frame(width: 43, height: 43)
                                .background(model.accent.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 15))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Каталог Apple Music")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(RhythmPalette.text(light))
                                Text("Поиск и превью доступны, если MusicKit включён для приложения и разрешён в iOS. Полные композиции пока не воспроизводятся.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(RhythmPalette.muted(light))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            Circle()
                                .fill(Color.orange.opacity(0.9))
                                .frame(width: 7, height: 7)
                        }
                        .padding(15)
                    }
                }

                SurfaceCard(light: light) {
                    HStack(spacing: 12) {
                        Image(systemName: "iphone")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(model.accent.color)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Твоя коллекция хранится на устройстве")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(RhythmPalette.text(light))
                            Text("Лайки, библиотека и плейлисты останутся после перезапуска.")
                                .font(.system(size: 11))
                                .foregroundStyle(RhythmPalette.muted(light))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func appearanceSymbol(_ appearance: AppAppearance) -> String {
        switch appearance {
        case .system: "circle.lefthalf.filled"
        case .dark: "moon.stars.fill"
        case .light: "sun.max.fill"
        }
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String
    let symbol: String
    @ObservedObject var model: RhythmAppModel
    private var light: Bool { model.appearance == .light }

    var body: some View {
        SurfaceCard(light: light) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(model.accent.color)
                    .frame(width: 40, height: 40)
                    .background(model.accent.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(RhythmPalette.text(light))
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(RhythmPalette.muted(light))
                }
                Spacer(minLength: 0)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PlaylistCard: View {
    let playlist: RhythmPlaylist
    let count: Int
    let light: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: playlist.tone.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "waveform")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .frame(width: 94, height: 82)
            Text(playlist.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RhythmPalette.text(light))
                .lineLimit(1)
            Text("\(count) треков")
                .font(.system(size: 10))
                .foregroundStyle(RhythmPalette.muted(light))
                .padding(.top, -8)
        }
        .frame(width: 112, height: 126, alignment: .topLeading)
        .padding(9)
        .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(RhythmPalette.border(light), lineWidth: 1))
    }
}

struct EmptyPanel: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    @ObservedObject var model: RhythmAppModel
    private var light: Bool { model.appearance == .light }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(model.accent.color)
                .padding(.bottom, 2)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RhythmPalette.text(light))
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(RhythmPalette.muted(light))
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(model.accent.color)
                    .padding(.top, 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(RhythmPalette.border(light), lineWidth: 1))
    }
}

struct TrackRow: View {
    @ObservedObject var model: RhythmAppModel
    let track: Track
    let onPlay: () -> Void
    var position: Int? = nil
    var removeFromPlaylist: (() -> Void)? = nil
    private var light: Bool { model.appearance == .light }

    var body: some View {
        HStack(spacing: 11) {
            if let position {
                Text(String(format: "%02d", position))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(RhythmPalette.muted(light))
                    .frame(width: 23)
            }

            Button(action: onPlay) {
                HStack(spacing: 11) {
                    TrackArtwork(track: track, size: 54, showsTitle: false)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RhythmPalette.text(light))
                            .lineLimit(1)
                        Text(track.audioSource == .appleMusicPreview ? "\(track.artist) · превью" : track.artist)
                            .font(.system(size: 12))
                            .foregroundStyle(RhythmPalette.muted(light))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 2)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button(model.savedIDs.contains(track.id) ? "Убрать из библиотеки" : "Добавить в библиотеку", systemImage: model.savedIDs.contains(track.id) ? "bookmark.slash" : "bookmark") {
                    model.toggleSaved(track)
                }
                Button(model.likedIDs.contains(track.id) ? "Убрать из любимого" : "Мне нравится", systemImage: model.likedIDs.contains(track.id) ? "heart.slash" : "heart") {
                    model.toggleLiked(track)
                }
                if !model.playlists.isEmpty {
                    Menu("Добавить в плейлист", systemImage: "text.badge.plus") {
                        ForEach(model.playlists) { playlist in
                            Button(playlist.name) { model.add(track, to: playlist.id) }
                        }
                    }
                }
                if let removeFromPlaylist {
                    Button("Убрать из этого плейлиста", systemImage: "minus.circle", role: .destructive, action: removeFromPlaylist)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RhythmPalette.muted(light))
                    .frame(width: 40, height: 44)
                    .contentShape(Rectangle())
            }

        }
        .padding(.vertical, 5)
    }
}

private struct MiniPlayer: View {
    @ObservedObject var model: RhythmAppModel
    let track: Track
    let openPlayer: () -> Void
    private var light: Bool { model.appearance == .light }

    var body: some View {
        HStack(spacing: 11) {
            Button(action: openPlayer) {
                HStack(spacing: 11) {
                    TrackArtwork(track: track, size: 48, showsTitle: false)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(RhythmPalette.text(light))
                            .lineLimit(1)
                        Text(track.audioSource == .appleMusicPreview ? "\(track.artist) · превью" : track.artist)
                            .font(.system(size: 11))
                            .foregroundStyle(RhythmPalette.muted(light))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: model.togglePlayback) {
                Image(systemName: model.isLoading ? "ellipsis" : (model.isPlaying ? "pause.fill" : "play.fill"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(model.accent.color)
                    .frame(width: 42, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.isPlaying ? "Пауза" : "Воспроизвести")
        }
        .padding(9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background(RhythmPalette.surface(light), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(RhythmPalette.border(light), lineWidth: 1))
        .shadow(color: .black.opacity(light ? 0.06 : 0.24), radius: 18, y: 7)
    }
}

private struct BottomNavigation: View {
    @Binding var selectedTab: RhythmTab
    @ObservedObject var model: RhythmAppModel
    private var light: Bool { model.appearance == .light }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RhythmTab.allCases) { tab in
                Button { selectedTab = tab } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                            .frame(height: 22)
                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selectedTab == tab ? model.accent.color : RhythmPalette.muted(light))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 11)
        .padding(.bottom, 7)
        .background(.ultraThinMaterial)
        .background(RhythmPalette.background(light).opacity(0.92))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RhythmPalette.border(light))
                .frame(height: 0.5)
        }
    }
}
