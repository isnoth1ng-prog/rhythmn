import SwiftUI
import Combine

enum RepeatMode: String, CaseIterable {
    case off, all, one
    
    var icon: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
    
    var isActive: Bool { self != .off }
}

@MainActor
class PlayerViewModel: ObservableObject {
    @Published var currentTrack: Track?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0
    @Published var queue: [Track] = []
    @Published var currentIndex: Int = 0
    @Published var isShuffled = false
    @Published var repeatMode: RepeatMode = .off
    @Published var lyrics: Lyrics?
    @Published var showFullPlayer = false
    @Published var isLoadingStream = false
    @Published var currentLyricIndex: Int = 0
    
    private let audioService = AudioPlayerService.shared
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var originalQueue: [Track] = []
    
    init() {
        // Forward audioService.isPlaying -> self.isPlaying
        audioService.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)
        
        // Forward audioService.currentTime -> self.currentTime, update progress and lyric index
        audioService.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                guard let self = self else { return }
                self.currentTime = time
                self.progress = self.duration > 0 ? time / self.duration : 0
                self.updateCurrentLyricIndex()
            }
            .store(in: &cancellables)
        
        // Forward audioService.duration -> self.duration
        audioService.$duration
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)
        
        // Handle track end
        audioService.onTrackEnd = { [weak self] in
            Task { @MainActor in
                self?.handleTrackEnd()
            }
        }
    }
    
    func play(track: Track) {
        currentTrack = track
        queue = [track]
        currentIndex = 0
        originalQueue = [track]
        loadStreamAndPlay(track: track)
    }
    
    func playQueue(tracks: [Track], startIndex: Int) {
        guard !tracks.isEmpty, startIndex >= 0, startIndex < tracks.count else { return }
        queue = tracks
        originalQueue = tracks
        currentIndex = startIndex
        currentTrack = tracks[startIndex]
        if isShuffled {
            shuffleQueue()
        }
        loadStreamAndPlay(track: tracks[startIndex])
    }
    
    func togglePlayPause() {
        audioService.togglePlayPause()
    }
    
    func next() {
        guard !queue.isEmpty else { return }
        if currentIndex < queue.count - 1 {
            currentIndex += 1
        } else if repeatMode == .all {
            currentIndex = 0
        } else {
            return
        }
        currentTrack = queue[currentIndex]
        loadStreamAndPlay(track: queue[currentIndex])
    }
    
    func previous() {
        if currentTime > 3 {
            seek(to: 0)
        } else if currentIndex > 0 {
            currentIndex -= 1
            currentTrack = queue[currentIndex]
            loadStreamAndPlay(track: queue[currentIndex])
        }
    }
    
    func seek(to time: TimeInterval) {
        audioService.seek(to: time)
    }
    
    func seek(toProgress prog: Double) {
        let time = prog * duration
        seek(to: time)
    }
    
    func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            shuffleQueue()
        } else {
            queue = originalQueue
            if let track = currentTrack {
                currentIndex = queue.firstIndex(of: track) ?? 0
            }
        }
    }
    
    func toggleRepeat() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }
    
    private func loadStreamAndPlay(track: Track) {
        isLoadingStream = true
        lyrics = nil
        currentLyricIndex = 0
        
        // Fast-path: if the track already contains a valid stream URL, start playback immediately
        if let directUrl = track.streamUrl, !directUrl.isEmpty, let streamURL = URL(string: directUrl) {
            audioService.play(url: streamURL)
            isLoadingStream = false
            loadLyrics(for: track)
            return
        }
        
        Task {
            do {
                let url = try await apiService.getStreamUrl(
                    trackId: track.id,
                    title: track.title,
                    artist: track.artist
                )
                if !url.isEmpty, let streamURL = URL(string: url) {
                    audioService.play(url: streamURL)
                }
                isLoadingStream = false
            } catch {
                print("Stream error: \(error)")
                isLoadingStream = false
            }
        }
        loadLyrics(for: track)
    }
    
    private func loadLyrics(for track: Track) {
        Task {
            do {
                let l = try await apiService.getLyrics(
                    title: track.title,
                    artist: track.artist,
                    duration: Int(track.duration)
                )
                await MainActor.run { self.lyrics = l }
            } catch {
                print("Lyrics error: \(error)")
            }
        }
    }
    
    private func updateCurrentLyricIndex() {
        guard let lines = lyrics?.lines, !lines.isEmpty else { return }
        var newIndex = 0
        for (i, line) in lines.enumerated() {
            if currentTime >= line.time {
                newIndex = i
            } else {
                break
            }
        }
        if newIndex != currentLyricIndex {
            currentLyricIndex = newIndex
        }
    }
    
    private func handleTrackEnd() {
        if repeatMode == .one {
            seek(to: 0)
            audioService.resume()
        } else {
            next()
        }
    }
    
    private func shuffleQueue() {
        guard let track = currentTrack else { return }
        var shuffled = queue.filter { $0 != track }
        shuffled.shuffle()
        shuffled.insert(track, at: 0)
        queue = shuffled
        currentIndex = 0
    }
}
