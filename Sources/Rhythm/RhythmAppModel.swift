import ActivityKit
import AVFAudio
import AVFoundation
import Combine
import Foundation
import MediaPlayer
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, dark, light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Как в системе"
        case .dark: "Тёмная"
        case .light: "Светлая"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

enum AccentTone: String, CaseIterable, Identifiable {
    case mint, ice, violet, coral, lime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mint: "Мята"
        case .ice: "Лёд"
        case .violet: "Лиловый"
        case .coral: "Коралл"
        case .lime: "Лайм"
        }
    }

    var color: Color {
        switch self {
        case .mint: Color(red: 0.37, green: 0.88, blue: 0.72)
        case .ice: Color(red: 0.43, green: 0.78, blue: 0.98)
        case .violet: Color(red: 0.73, green: 0.60, blue: 0.98)
        case .coral: Color(red: 1.00, green: 0.51, blue: 0.42)
        case .lime: Color(red: 0.76, green: 0.88, blue: 0.38)
        }
    }
}

enum RhythmTab: String, CaseIterable, Identifiable {
    case home, wave, search, library, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Главная"
        case .wave: "Моя волна"
        case .search: "Поиск"
        case .library: "Коллекция"
        case .settings: "Настройки"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .wave: "waveform.path"
        case .search: "magnifyingglass"
        case .library: "square.stack.3d.up"
        case .settings: "slider.horizontal.3"
        }
    }
}

@MainActor
final class RhythmAppModel: ObservableObject {
    @Published private(set) var tracks: [Track] = DemoCatalog.tracks
    @Published private(set) var catalogSearchResults: [Track] = []
    @Published private(set) var catalogSearchMessage: String?
    @Published private(set) var isSearchingCatalog = false
    @Published private(set) var didSearchCatalog = false
    @Published private(set) var savedIDs: Set<String>
    @Published private(set) var likedIDs: Set<String>
    @Published private(set) var recentIDs: [String]
    @Published private(set) var playCounts: [String: Int]
    @Published var playlists: [RhythmPlaylist]
    @Published var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "rhythm.v2.appearance") }
    }
    @Published var accent: AccentTone {
        didSet { UserDefaults.standard.set(accent.rawValue, forKey: "rhythm.v2.accent") }
    }
    @Published var minimalEffects: Bool {
        didSet { UserDefaults.standard.set(minimalEffects, forKey: "rhythm.v2.minimalEffects") }
    }
    @Published var animationsEnabled: Bool {
        didSet { UserDefaults.standard.set(animationsEnabled, forKey: "rhythm.v2.animationsEnabled") }
    }

    @Published private(set) var currentTrack: Track?
    @Published private(set) var currentLyrics: [LyricLine] = []
    @Published private(set) var isPlaying = false
    @Published private(set) var isLoading = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var playbackNotice: String?
    @Published private(set) var waveQueue: [Track] = []
    @Published var waveMood = "Случайно"
    @Published var isShuffling = false
    @Published var repeatMode: RepeatMode = .off

    private let source: MusicSource
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var queue = PlaybackQueue()
    private var activeRequest = UUID()
    private var catalogSearchRequest = UUID()

    init(source: MusicSource = MusicKitMusicSource()) {
        self.source = source
        tracks = Self.load([Track].self, key: "rhythm.v2.catalogCache", fallback: DemoCatalog.tracks)
        savedIDs = Self.load(Set<String>.self, key: "rhythm.v2.saved", fallback: [])
        likedIDs = Self.load(Set<String>.self, key: "rhythm.v2.liked", fallback: [])
        recentIDs = Self.load([String].self, key: "rhythm.v2.recent", fallback: [])
        playCounts = Self.load([String: Int].self, key: "rhythm.v2.playCounts", fallback: [:])
        playlists = Self.load([RhythmPlaylist].self, key: "rhythm.v2.playlists", fallback: [])
        appearance = AppAppearance(rawValue: UserDefaults.standard.string(forKey: "rhythm.v2.appearance") ?? "") ?? .dark
        accent = AccentTone(rawValue: UserDefaults.standard.string(forKey: "rhythm.v2.accent") ?? "") ?? .mint
        minimalEffects = UserDefaults.standard.bool(forKey: "rhythm.v2.minimalEffects")
        animationsEnabled = UserDefaults.standard.object(forKey: "rhythm.v2.animationsEnabled") as? Bool ?? true
        RhythmNowPlayingController.configure(
            play: { [weak self] in
                guard let self, !self.isPlaying else { return }
                self.togglePlayback()
            },
            pause: { [weak self] in
                guard let self, self.isPlaying else { return }
                self.togglePlayback()
            },
            toggle: { [weak self] in self?.togglePlayback() },
            next: { [weak self] in self?.nextTrack() },
            previous: { [weak self] in self?.previousTrack() },
            seek: { [weak self] time in self?.seek(to: time) }
        )
        Task { await reloadCatalog() }
    }

    var savedTracks: [Track] {
        tracks.filter { savedIDs.contains($0.id) }
    }

    var likedTracks: [Track] {
        tracks.filter { likedIDs.contains($0.id) }
    }

    var recentlyPlayed: [Track] {
        recentIDs.compactMap { id in tracks.first { $0.id == id } }
    }

    func tracks(for artistID: String) -> [Track] {
        tracks.filter { $0.artistID == artistID }
    }

    func tracks(in playlist: RhythmPlaylist) -> [Track] {
        playlist.trackIDs.compactMap { id in tracks.first { $0.id == id } }
    }

    func searchTracks(_ query: String) -> [Track] {
        let needle = Self.normalized(query)
        guard !needle.isEmpty else { return tracks }
        return tracks.filter {
            Self.normalized([$0.title, $0.artist, $0.album, $0.tags.joined(separator: " ")].joined(separator: " "))
                .contains(needle)
        }
    }

    func searchArtists(_ query: String) -> [ArtistProfile] {
        let needle = Self.normalized(query)
        guard !needle.isEmpty else { return [] }
        let artistIDs = Set(tracks.map(\.artistID))
        return artistIDs.compactMap { artistID in
            let track = tracks.first { $0.artistID == artistID }
            let known = DemoCatalog.artists.first { $0.id == artistID }
            let profile = known ?? track.map {
                ArtistProfile(
                    id: artistID,
                    name: $0.artist,
                    note: $0.audioSource == .appleMusicPreview ? "Apple Music" : "Исполнитель Rhythm",
                    tone: $0.tone
                )
            }
            guard let profile,
                  Self.normalized("\(profile.name) \(profile.note)").contains(needle) else { return nil }
            return profile
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func artistProfile(id: String) -> ArtistProfile? {
        if let known = DemoCatalog.artists.first(where: { $0.id == id }) { return known }
        guard let track = tracks.first(where: { $0.artistID == id }) else { return nil }
        return ArtistProfile(
            id: id,
            name: track.artist,
            note: track.audioSource == .appleMusicPreview ? "Apple Music" : "Исполнитель Rhythm",
            tone: track.tone
        )
    }

    func clearCatalogSearch() {
        catalogSearchRequest = UUID()
        catalogSearchResults = []
        catalogSearchMessage = nil
        isSearchingCatalog = false
        didSearchCatalog = false
    }

    func searchCatalog(_ query: String) async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            clearCatalogSearch()
            return
        }

        let requestID = UUID()
        catalogSearchRequest = requestID
        isSearchingCatalog = true
        catalogSearchMessage = nil
        didSearchCatalog = false
        defer {
            if catalogSearchRequest == requestID {
                isSearchingCatalog = false
            }
        }

        do {
            let results = try await source.searchCatalog(term)
            guard catalogSearchRequest == requestID else { return }
            catalogSearchResults = results
            didSearchCatalog = true
            if results.isEmpty {
                catalogSearchMessage = "В Apple Music не нашлось треков по этому запросу. Ниже показан локальный демо-каталог."
                return
            }
            let resultIDs = Set(results.map(\.id))
            tracks = Array((results + tracks.filter { !resultIDs.contains($0.id) }).prefix(500))
            Self.save(tracks, key: "rhythm.v2.catalogCache")
        } catch {
            guard catalogSearchRequest == requestID else { return }
            catalogSearchResults = []
            didSearchCatalog = true
            catalogSearchMessage = "Apple Music сейчас недоступен: \(error.localizedDescription) Локальный демо-каталог остаётся доступен."
        }
    }

    func toggleSaved(_ track: Track) {
        if savedIDs.contains(track.id) { savedIDs.remove(track.id) }
        else { savedIDs.insert(track.id) }
        Self.save(savedIDs, key: "rhythm.v2.saved")
    }

    func toggleLiked(_ track: Track) {
        if likedIDs.contains(track.id) { likedIDs.remove(track.id) }
        else { likedIDs.insert(track.id) }
        Self.save(likedIDs, key: "rhythm.v2.liked")
    }

    func createPlaylist(_ name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        let tones = ArtworkTone.allCases
        playlists.insert(
            RhythmPlaylist(id: UUID().uuidString, name: cleanName, trackIDs: [], tone: tones.randomElement() ?? .glacier),
            at: 0
        )
        Self.save(playlists, key: "rhythm.v2.playlists")
    }

    func add(_ track: Track, to playlistID: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        if !playlists[index].trackIDs.contains(track.id) {
            playlists[index].trackIDs.append(track.id)
            Self.save(playlists, key: "rhythm.v2.playlists")
        }
    }

    func remove(_ track: Track, from playlistID: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[index].trackIDs.removeAll { $0 == track.id }
        Self.save(playlists, key: "rhythm.v2.playlists")
    }

    func refreshWave() {
        waveQueue = LocalRecommendationEngine.rank(
            tracks: tracks,
            mood: waveMood,
            likedIDs: likedIDs,
            recentIDs: recentIDs,
            playCounts: playCounts
        )
    }

    func playFromWave(_ track: Track) {
        if waveQueue.isEmpty { refreshWave() }
        play(track, in: waveQueue)
    }

    func play(_ track: Track, in proposedQueue: [Track]? = nil) {
        playbackNotice = nil
        queue.select(track, from: proposedQueue)

        currentTrack = track
        currentLyrics = track.lyrics
        currentTime = 0
        RhythmNowPlayingController.update(track: track, playbackTime: 0, duration: track.duration, isPlaying: false)
        duration = track.duration
        Task { await resolveAndPlay(track) }
    }

    func togglePlayback() {
        guard let currentTrack else { return }
        guard !isLoading else { return }
        guard let player else {
            Task { await resolveAndPlay(currentTrack) }
            return
        }

        if isPlaying {
            player.pause()
            isPlaying = false
            RhythmNowPlayingController.update(track: currentTrack, playbackTime: currentTime, duration: duration, isPlaying: false)
            Task { await RhythmActivityController.endAll() }
        } else {
            player.play()
            isPlaying = true
            RhythmNowPlayingController.update(track: currentTrack, playbackTime: currentTime, duration: duration, isPlaying: true)
            Task { await RhythmActivityController.start(trackTitle: currentTrack.title, artist: currentTrack.artist) }
        }
    }

    func stopPlayback() {
        activeRequest = UUID()
        isLoading = false
        clearPlayer()
        currentTrack = nil
        RhythmNowPlayingController.clear()
        currentLyrics = []
        currentTime = 0
        duration = 0
        isPlaying = false
        Task { await RhythmActivityController.endAll() }
    }

    func seek(to time: TimeInterval) {
        let clamped = min(max(0, time), max(duration, 0))
        currentTime = clamped
        RhythmNowPlayingController.update(track: currentTrack, playbackTime: clamped, duration: duration, isPlaying: isPlaying)
        guard let player else { return }
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600))
    }

    func skipForward() {
        seek(to: currentTime + 15)
    }

    func skipBackward() {
        seek(to: currentTime - 15)
    }

    func previousTrack() {
        guard !queue.tracks.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        let currentQueue = queue.tracks
        guard let previous = queue.previous() else { return }
        play(previous, in: currentQueue)
    }

    func nextTrack() {
        guard let next = queue.advance(shuffling: isShuffling, repeatMode: repeatMode) else {
            stopPlayback()
            return
        }
        play(next, in: queue.tracks)
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    func cycleShuffle() {
        isShuffling.toggle()
    }

    func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "0:00" }
        let seconds = max(Int(time), 0)
        return "\(seconds / 60):" + String(format: "%02d", seconds % 60)
    }

    private func reloadCatalog() async {
        do {
            let loaded = try await source.loadCatalog()
            guard !loaded.isEmpty else { return }
            let loadedIDs = Set(loaded.map(\.id))
            tracks = Array((loaded + tracks.filter { !loadedIDs.contains($0.id) }).prefix(500))
            Self.save(tracks, key: "rhythm.v2.catalogCache")
            refreshWave()
        } catch {
            playbackNotice = "Не удалось загрузить каталог: \(error.localizedDescription)"
        }
    }

    private func resolveAndPlay(_ track: Track) async {
        let requestID = UUID()
        activeRequest = requestID
        isLoading = true
        defer {
            if activeRequest == requestID { isLoading = false }
        }

        do {
            let url = try await source.audioURL(for: track)
            guard activeRequest == requestID else { return }
            guard let url else {
                clearPlayer()
                isPlaying = false
                playbackNotice = track.audioSource == .appleMusicPreview
                    ? "У этого результата нет доступного аудиопревью Apple Music."
                    : "Демо-каталог содержит только тестовые метаданные. Найди трек в Apple Music, чтобы послушать доступное превью."
                RhythmNowPlayingController.update(track: track, playbackTime: 0, duration: track.duration, isPlaying: false)
                await RhythmActivityController.endAll()
                do {
                    currentLyrics = try await source.lyrics(for: track) ?? track.lyrics
                } catch {
                    currentLyrics = track.lyrics
                }
                return
            }

            clearPlayer()
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                clearPlayer()
                isPlaying = false
                playbackNotice = "Не удалось подготовить аудиосессию: \(error.localizedDescription)"
                RhythmNowPlayingController.update(track: track, playbackTime: currentTime, duration: duration, isPlaying: false)
                await RhythmActivityController.endAll()
                return
            }

            let item = AVPlayerItem(url: url)
            let newPlayer = AVPlayer(playerItem: item)
            player = newPlayer
            duration = track.duration
            addObservers(for: item, player: newPlayer)
            newPlayer.play()
            isPlaying = true
            RhythmNowPlayingController.update(track: track, playbackTime: 0, duration: duration, isPlaying: true)
            playbackNotice = nil
            recordPlayed(track)
            await RhythmActivityController.start(trackTitle: track.title, artist: track.artist)
            do {
                currentLyrics = try await source.lyrics(for: track) ?? track.lyrics
            } catch {
                currentLyrics = track.lyrics
            }
        } catch {
            guard activeRequest == requestID else { return }
            clearPlayer()
            isPlaying = false
            playbackNotice = "Не удалось открыть аудио: \(error.localizedDescription)"
            RhythmNowPlayingController.update(track: currentTrack, playbackTime: currentTime, duration: duration, isPlaying: false)
            await RhythmActivityController.endAll()
        }
    }

    private func recordPlayed(_ track: Track) {
        playCounts[track.id, default: 0] += 1
        recentIDs.removeAll { $0 == track.id }
        recentIDs.insert(track.id, at: 0)
        recentIDs = Array(recentIDs.prefix(30))
        Self.save(playCounts, key: "rhythm.v2.playCounts")
        Self.save(recentIDs, key: "rhythm.v2.recent")
        refreshWave()
    }

    private func addObservers(for item: AVPlayerItem, player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.4, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            let seconds = time.seconds
            Task { @MainActor [weak self] in
                guard let self, seconds.isFinite else { return }
                self.currentTime = seconds
                if let itemDuration = self.player?.currentItem?.duration.seconds, itemDuration.isFinite, itemDuration > 0 {
                    self.duration = itemDuration
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.nextTrack()
            }
        }
    }

    private func clearPlayer() {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        player?.pause()
        player = nil
    }

    private static func normalized(_ string: String) -> String {
        string.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func load<Value: Decodable>(_ type: Value.Type, key: String, fallback: Value) -> Value {
        guard let data = UserDefaults.standard.data(forKey: key) else { return fallback }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Rhythm could not restore saved data for \(key): \(error.localizedDescription)")
            return fallback
        }
    }

    private static func save<Value: Encodable>(_ value: Value, key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Rhythm could not encode saved data for \(key): \(error.localizedDescription)")
        }
    }
}
