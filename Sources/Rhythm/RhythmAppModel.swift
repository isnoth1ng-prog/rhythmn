import ActivityKit
import AVFAudio
import AVFoundation
import Combine
import Foundation
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

enum RepeatMode: String {
    case off, all, one

    var icon: String {
        switch self {
        case .off: "repeat"
        case .all: "repeat"
        case .one: "repeat.1"
        }
    }
}

enum RhythmTab: String, CaseIterable, Identifiable {
    case library, search, wave, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .library: "Музыка"
        case .search: "Поиск"
        case .wave: "Волна"
        case .settings: "Настройки"
        }
    }

    var symbol: String {
        switch self {
        case .library: "square.stack.3d.up"
        case .search: "magnifyingglass"
        case .wave: "waveform.path"
        case .settings: "slider.horizontal.3"
        }
    }
}

@MainActor
final class RhythmAppModel: ObservableObject {
    @Published private(set) var tracks: [Track] = DemoCatalog.tracks
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
    private var queue: [Track] = []
    private var queueIndex = 0
    private var activeRequest = UUID()

    init(source: MusicSource = DemoMusicSource()) {
        self.source = source
        savedIDs = Self.load(Set<String>.self, key: "rhythm.v2.saved", fallback: [])
        likedIDs = Self.load(Set<String>.self, key: "rhythm.v2.liked", fallback: [])
        recentIDs = Self.load([String].self, key: "rhythm.v2.recent", fallback: [])
        playCounts = Self.load([String: Int].self, key: "rhythm.v2.playCounts", fallback: [:])
        playlists = Self.load([RhythmPlaylist].self, key: "rhythm.v2.playlists", fallback: [])
        appearance = AppAppearance(rawValue: UserDefaults.standard.string(forKey: "rhythm.v2.appearance") ?? "") ?? .dark
        accent = AccentTone(rawValue: UserDefaults.standard.string(forKey: "rhythm.v2.accent") ?? "") ?? .mint
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
        return DemoCatalog.artists.filter {
            Self.normalized("\($0.name) \($0.note)").contains(needle)
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
        let likedTags = likedTracks.flatMap(\.tags)
        let historyTags = recentlyPlayed.prefix(4).flatMap(\.tags)
        var candidates = tracks.filter { !recentIDs.prefix(3).contains($0.id) }
        if candidates.isEmpty { candidates = tracks }

        waveQueue = candidates
            .map { track -> (Track, Double) in
                var score = Double.random(in: 0...0.8)
                if waveMood != "Случайно", track.tags.contains(waveMood) { score += 4 }
                score += Double(likedTags.filter { track.tags.contains($0) }.count) * 1.7
                score += Double(historyTags.filter { track.tags.contains($0) }.count) * 0.35
                score -= Double(playCounts[track.id, default: 0]) * 0.4
                return (track, score)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    func playFromWave(_ track: Track) {
        if waveQueue.isEmpty { refreshWave() }
        play(track, in: waveQueue)
    }

    func play(_ track: Track, in proposedQueue: [Track]? = nil) {
        playbackNotice = nil
        if let proposedQueue, !proposedQueue.isEmpty {
            queue = proposedQueue
            queueIndex = queue.firstIndex(where: { $0.id == track.id }) ?? 0
        } else if queue.firstIndex(where: { $0.id == track.id }) == nil {
            queue = [track]
            queueIndex = 0
        } else {
            queueIndex = queue.firstIndex(where: { $0.id == track.id }) ?? 0
        }

        currentTrack = track
        currentLyrics = track.lyrics
        currentTime = 0
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
            Task { await RhythmActivityController.endAll() }
        } else {
            player.play()
            isPlaying = true
            Task { await RhythmActivityController.start(trackTitle: currentTrack.title, artist: currentTrack.artist) }
        }
    }

    func stopPlayback() {
        activeRequest = UUID()
        isLoading = false
        clearPlayer()
        currentTrack = nil
        currentLyrics = []
        currentTime = 0
        duration = 0
        isPlaying = false
        Task { await RhythmActivityController.endAll() }
    }

    func seek(to time: TimeInterval) {
        let clamped = min(max(0, time), max(duration, 0))
        currentTime = clamped
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
        guard !queue.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        let previous = max(queueIndex - 1, 0)
        queueIndex = previous
        play(queue[previous], in: queue)
    }

    func nextTrack() {
        guard !queue.isEmpty else { return }
        if repeatMode == .one, let currentTrack {
            play(currentTrack, in: queue)
            return
        }
        if isShuffling, queue.count > 1 {
            let choices = queue.indices.filter { $0 != queueIndex }
            queueIndex = choices.randomElement() ?? queueIndex
        } else if queueIndex + 1 < queue.count {
            queueIndex += 1
        } else if repeatMode == .all {
            queueIndex = 0
        } else {
            stopPlayback()
            return
        }
        play(queue[queueIndex], in: queue)
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
            tracks = loaded
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
                playbackNotice = "Аудиоисточник не подключён. Этот экран готов к подключению через MusicSource.swift."
                await RhythmActivityController.endAll()
                if let lyrics = try? await source.lyrics(for: track) {
                    currentLyrics = lyrics
                }
                return
            }

            clearPlayer()
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try? AVAudioSession.sharedInstance().setActive(true)

            let item = AVPlayerItem(url: url)
            let newPlayer = AVPlayer(playerItem: item)
            player = newPlayer
            duration = track.duration
            addObservers(for: item, player: newPlayer)
            newPlayer.play()
            isPlaying = true
            playbackNotice = nil
            recordPlayed(track)
            await RhythmActivityController.start(trackTitle: track.title, artist: track.artist)
            if let lyrics = try? await source.lyrics(for: track{
                currentLyrics = lyrics
            }
        } catch {
            guard activeRequest == requestID else { return }
            clearPlayer()
            isPlaying = false
            playbackNotice = "Не удалось открыть аудио: \(error.localizedDescription)"
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
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(type, from: data) else { return fallback }
        return decoded
    }

    private static func save<Value: Encodable>(_ value: Value, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
