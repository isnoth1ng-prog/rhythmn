import AVFoundation
import Combine

class AudioPlayerService: ObservableObject {
    static let shared = AudioPlayerService()
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isBuffering: Bool = false
    
    var progress: Double { duration > 0 ? currentTime / duration : 0 }
    
    var onTrackEnd: (() -> Void)?
    
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Public Controls
    
    func play(url: URL) {
        stop()
        
        let item = AVPlayerItem(url: url)
        self.playerItem = item
        
        if player == nil {
            player = AVPlayer(playerItem: item)
        } else {
            player?.replaceCurrentItem(with: item)
        }
        
        observePlayerItem()
        setupTimeObserver()
        
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func resume() {
        player?.play()
        isPlaying = true
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            if finished {
                DispatchQueue.main.async {
                    self?.currentTime = time
                }
            }
        }
    }
    
    func stop() {
        player?.pause()
        removeTimeObserver()
        cancellables.removeAll()
        playerItem = nil
        player?.replaceCurrentItem(with: nil)
        isPlaying = false
        currentTime = 0
        duration = 0
        isBuffering = false
    }
    
    // MARK: - Private Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func setupTimeObserver() {
        removeTimeObserver()
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(time)
            if seconds.isFinite && seconds >= 0 {
                self.currentTime = seconds
            }
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func observePlayerItem() {
        cancellables.removeAll()
        
        guard let item = playerItem else { return }
        
        // Observe player item status for duration
        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                if status == .readyToPlay {
                    let seconds = CMTimeGetSeconds(item.duration)
                    if seconds.isFinite && seconds > 0 {
                        self.duration = seconds
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe time control status for buffering/playing state
        player?.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .playing:
                    self.isPlaying = true
                    self.isBuffering = false
                case .paused:
                    self.isPlaying = false
                    self.isBuffering = false
                case .waitingToPlayAtSpecifiedRate:
                    self.isBuffering = true
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe track end notification
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPlaying = false
                self?.onTrackEnd?()
            }
            .store(in: &cancellables)
        
        // Observe playback stall
        NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isBuffering = true
            }
            .store(in: &cancellables)
    }
}
