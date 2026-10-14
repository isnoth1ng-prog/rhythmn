import SwiftUI
import AVFoundation
import AVFAudio
import ActivityKit

private struct Track: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let genre: String
    let audioURL: URL
    static let sample = Track(
        id: "saints-pd",
        title: "When the Saints Go Marching In",
        artist: "Traditional",
        genre: "Folk",
        audioURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/transcoded/0/06/When_the_Saints_Go_Marching_In.ogg/When_the_Saints_Go_Marching_In.ogg.mp3")!
    )
}

private enum Tab: String, CaseIterable, Identifiable {
    case library = "Моя музыка", search = "Поиск", wave = "Моя волна", settings = "Настройки"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .library: "square.stack.fill"
        case .search: "magnifyingglass"
        case .wave: "waveform.path"
        case .settings: "slider.horizontal.3"
        }
    }
}

struct ContentView: View {
    @AppStorage("rhythm.accent") private var accentName = "Мята"
    @AppStorage("rhythm.appearance") private var appearance = "Тёмная"
    @AppStorage("rhythm.saved") private var saved = false
    @State private var tab: Tab = .library
    @State private var query = ""
    @State private var playerOpen = false
    @State private var artistOpen = false
    @State private var lyricsVisible = true
    @State private var isPlaying = false
    @State private var player: AVPlayer?
    @State private var wave: [Track] = [.sample]
    @State private var waveIndex = 0
    @State private var isShuffling = false
    @State private var repeatsTrack = false

    private var track: Track { wave.indices.contains(waveIndex) ? wave[waveIndex] : .sample }
    private var dark: Bool { appearance == "Тёмная" }
    private var ink: Color { dark ? .white : Color(red: 0.08, green: 0.09, blue: 0.1) }
    private var muted: Color { ink.opacity(0.55) }
    private var panel: Color { dark ? Color.white.opacity(0.075) : Color.black.opacity(0.045) }
    private var accent: Color {
        switch accentName {
        case "Фиолетовый": .purple
        case "Янтарный": .orange
        case "Ледяной": .cyan
        default: Color(red: 0.38, green: 0.84, blue: 0.69)
        }
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            TabView(selection: $tab) {
                library.tabItem { Label(Tab.library.rawValue, systemImage: Tab.library.icon) }.tag(Tab.library)
                search.tabItem { Label(Tab.search.rawValue, systemImage: Tab.search.icon) }.tag(Tab.search)
                waveView.tabItem { Label(Tab.wave.rawValue, systemImage: Tab.wave.icon) }.tag(Tab.wave)
                settings.tabItem { Label(Tab.settings.rawValue, systemImage: Tab.settings.icon) }.tag(Tab.settings)
            }
            .tint(accent)
            .toolbarBackground(dark ? Color.black : Color.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
        }
        .foregroundStyle(ink)
        .preferredColorScheme(dark ? .dark : .light)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fullScreenCover(isPresented: $playerOpen) { fullPlayer }
        .sheet(isPresented: $artistOpen) { artistSheet }
        .task { await RhythmActivityController.endAll() }
    }

    private var background: some View {
        ZStack {
            dark ? Color(red: 0.025, green: 0.035, blue: 0.045) : Color(red: 0.94, green: 0.95, blue: 0.96)
            RadialGradient(colors: [accent.opacity(dark ? 0.19 : 0.13), .clear], center: .topTrailing, startRadius: 4, endRadius: 460)
            LinearGradient(colors: [ink.opacity(0.025), .clear, accent.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            RhythmMark(color: accent, size: 32)
            Text("RHYTHM").font(.system(size: 13, weight: .bold, design: .rounded)).tracking(3)
            Spacer()
            Image(systemName: "waveform").foregroundStyle(accent)
        }
        .padding(.horizontal, 22).padding(.top, 7).padding(.bottom, 12)
    }

    private var library: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                title("Моя музыка", subtitle: "Треки, к которым хочется вернуться")

                HStack(spacing: 14) {
                    Artwork(size: 78, accent: accent)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ПРОДОЛЖАЙ СЛУШАТЬ")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(muted)
                        Text(Track.sample.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .lineLimit(2)
                        Text(Track.sample.artist)
                            .font(.system(size: 12))
                            .foregroundStyle(muted)
                    }
                    Spacer(minLength: 2)
                    Button {
                        wave = [.sample]
                        waveIndex = 0
                        playerOpen = true
                        if !isPlaying { togglePlayback() }
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(dark ? .black : .white)
                            .frame(width: 46, height: 46)
                            .background(accent, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPlaying ? "Пауза" : "Воспроизвести")
                }
                .padding(15)
                .background(
                    LinearGradient(colors: [accent.opacity(0.22), panel], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 23)
                )
                .overlay(RoundedRectangle(cornerRadius: 23).stroke(ink.opacity(0.07)))

                HStack {
                    Text("ТВОЯ КОЛЛЕКЦИЯ")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(muted)
                    Spacer()
                    Text(saved ? "1 ТРЕК" : "1 ТРЕК")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(accent)
                }

                HStack(spacing: 12) {
                    collectionCard(icon: "heart.fill", title: "Любимые", detail: saved ? "1 трек" : "Пока пусто", tint: accent)
                    collectionCard(icon: "clock.fill", title: "Недавно", detail: "1 прослушивание", tint: .cyan)
                }

                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Text("Тестовый трек")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Spacer()
                        Button { tab = .search } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(accent)
                                .frame(width: 36, height: 36)
                                .background(panel, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    trackRow(.sample)
                }

                HStack(spacing: 10) {
                    Image(systemName: "sparkles").foregroundStyle(accent)
                    Text("Новые треки и рекомендации появятся здесь, когда подключим музыкальный каталог.")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(panel.opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

        private var search: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                title("Поиск", subtitle: "Ищи треки и авторов")
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(accent)
                    TextField("Название или автор", text: $query).autocorrectionDisabled()
                }
                .padding(15).background(panel, in: RoundedRectangle(cornerRadius: 17))
                trackRow(.sample)
                Text("Онлайн-поиск музыкального каталога подключим отдельно.")
                    .font(.system(size: 12)).foregroundStyle(muted)
            }.padding(20)
        }
    }

    private var waveView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                title("Моя волна", subtitle: "Подборка обновляется по твоему настроению")
                HStack(spacing: 14) {
                    Image(systemName: "waveform.path").font(.system(size: 26)).foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Твоя волна").font(.system(size: 18, weight: .bold))
                        Text("Нажми обновить, чтобы собрать новую последовательность.")
                            .font(.system(size: 12)).foregroundStyle(muted)
                    }
                }
                .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [accent.opacity(0.22), panel], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 23))
                Button(action: refreshWave) {
                    Label("Обновить волну", systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(ink)
                        .padding(.horizontal, 17).padding(.vertical, 13).background(accent, in: Capsule())
                }
                trackRow(track)
                Text("Для автоматической выдачи новых реальных песен нужен онлайн-каталог. Пока подключён открытый тестовый аудиотрек; случайные вымышленные песни не выдаются за рекомендации.")
                    .font(.system(size: 11)).foregroundStyle(muted)
            }.padding(20)
        }
    }

    private var settings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 21) {
                title("Настройки", subtitle: "Оформи Rhythm под себя")
                section("Тема")
                HStack(spacing: 10) {
                    choice("Тёмная", selected: dark) { appearance = "Тёмная" }
                    choice("Светлая", selected: !dark) { appearance = "Светлая" }
                }
                section("Акцент")
                HStack(spacing: 10) {
                    accentChoice("Мята", color: Color(red: 0.38, green: 0.84, blue: 0.69))
                    accentChoice("Фиолетовый", color: .purple)
                    accentChoice("Янтарный", color: .orange)
                    accentChoice("Ледяной", color: .cyan)
                }
                section("Приложение")
                Text("Rhythm · музыкальный плеер в разработке")
                    .font(.system(size: 13)).foregroundStyle(muted)
            }.padding(20)
        }
    }

    private var miniPlayer: some View {
        HStack(spacing: 11) {
            Button { playerOpen = true } label: {
                HStack(spacing: 11) {
                    Artwork(size: 38, accent: accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                        Text(track.artist).font(.system(size: 10)).foregroundStyle(muted).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(accent)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Пауза" : "Воспроизвести")
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ink.opacity(0.08)))
        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 4)
        .background(dark ? Color.black : Color.white)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { item in
                Button { withAnimation(.snappy(duration: 0.22)) { tab = item } } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.icon).font(.system(size: 17, weight: .semibold))
                        Text(item.rawValue).font(.system(size: 9, weight: .medium)).lineLimit(1)
                    }
                    .foregroundStyle(tab == item ? accent : muted)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(ink.opacity(0.08)).frame(height: 0.5) }
    }

    private var fullPlayer: some View {
        GeometryReader { geometry in
            let artworkSize = min(252, min(geometry.size.width - 76, geometry.size.height * 0.31))
            ZStack {
                background.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Button { playerOpen = false } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(ink)
                                .frame(width: 44, height: 44)
                                .background(panel, in: Circle())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text("СЕЙЧАС ИГРАЕТ")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.6)
                            .foregroundStyle(muted)
                        Spacer()
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(ink)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            Artwork(size: artworkSize, accent: accent)
                                .shadow(color: accent.opacity(0.2), radius: 26, y: 12)
                                .padding(.top, 10)

                            VStack(spacing: 5) {
                                Text(track.title)
                                    .font(.system(size: 21, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                Button { artistOpen = true } label: {
                                    Text(track.artist)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(accent)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)

                            TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                                let rawTime = player?.currentTime().seconds ?? 0
                                let rawDuration = player?.currentItem?.duration.seconds ?? 0
                                let elapsed = rawTime.isFinite ? max(0, rawTime) : 0
                                let total = rawDuration.isFinite && rawDuration > 0 ? rawDuration : 1
                                VStack(spacing: 4) {
                                    Slider(
                                        value: Binding(
                                            get: { min(elapsed, total) },
                                            set: { player?.seek(to: CMTime(seconds: $0, preferredTimescale: 600)) }
                                        ),
                                        in: 0...total
                                    )
                                    .tint(accent)
                                    HStack {
                                        Text(timeLabel(elapsed))
                                        Spacer()
                                        Text(timeLabel(total))
                                    }
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(muted)
                                }
                            }

                            HStack(spacing: 0) {
                                playerModeButton("shuffle", selected: isShuffling) { isShuffling.toggle() }
                                Spacer()
                                playerControl("backward.end.fill", size: 19) { }
                                Spacer()
                                Button(action: togglePlayback) {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(dark ? .black : .white)
                                        .frame(width: 62, height: 62)
                                        .background(accent, in: Circle())
                                        .shadow(color: accent.opacity(0.28), radius: 14, y: 6)
                                }
                                .buttonStyle(.plain)
                                Spacer()
                                playerControl("forward.end.fill", size: 19) { }
                                Spacer()
                                playerModeButton("repeat", selected: repeatsTrack) { repeatsTrack.toggle() }
                            }
                            .padding(.horizontal, 2)

                            HStack {
                                Button { saved.toggle() } label: {
                                    Label(saved ? "Сохранено" : "В медиатеку", systemImage: saved ? "checkmark" : "plus")
                                }
                                Spacer()
                                Button { withAnimation(.spring(duration: 0.35)) { lyricsVisible.toggle() } } label: {
                                    Label(lyricsVisible ? "Скрыть текст" : "Текст", systemImage: "quote.bubble")
                                }
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accent)
                            .buttonStyle(.plain)
                            .padding(.top, 2)

                            if lyricsVisible {
                                TimelineView(.animation(minimumInterval: 0.35, paused: !isPlaying)) { timeline in
                                    let active = Int(timeline.date.timeIntervalSinceReferenceDate / 2.4) % 4
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("ТЕКСТ ПЕСНИ")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .tracking(1.5)
                                                .foregroundStyle(muted)
                                            Spacer()
                                            Image(systemName: "waveform")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(accent.opacity(0.75))
                                        }
                                        lyricLine("Oh, when the saints go marching in,", index: 0, active: active)
                                        lyricLine("Oh, when the saints go marching in,", index: 1, active: active)
                                        lyricLine("Lord, I want to be in that number,", index: 2, active: active)
                                        lyricLine("When the saints go marching in.", index: 3, active: active)
                                    }
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(panel, in: RoundedRectangle(cornerRadius: 20))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(ink.opacity(0.06)))
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(dark ? .dark : .light)
    }

        private func collectionCard(icon: String, title: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 11))
            Text(title).font(.system(size: 13, weight: .semibold))
            Text(detail).font(.system(size: 10)).foregroundStyle(muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(ink.opacity(0.06)))
    }

    private func trackRow(_ item: Track) -> some View {
        HStack(spacing: 13) {
            Artwork(size: 54, accent: accent)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                Text(item.artist).font(.system(size: 11)).foregroundStyle(muted).lineLimit(1)
            }
            Spacer()
            Button { playerOpen = true } label: {
                Image(systemName: "play.fill").foregroundStyle(accent).frame(width: 38, height: 38)
            }.buttonStyle(.plain)
        }
        .padding(10).background(panel, in: RoundedRectangle(cornerRadius: 17))
    }


    private func lyricLine(_ text: String, index: Int, active: Int) -> some View {
        Text(text)
            .foregroundStyle(index == active ? accent : ink.opacity(index < active ? 0.42 : 0.76))
            .scaleEffect(index == active ? 1.02 : 1, anchor: .leading)
            .animation(.easeInOut(duration: 0.4), value: active)
    }

    private var artistSheet: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Artwork(size: 64, accent: accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.artist).font(.title3.weight(.semibold))
                            Text("Исполнитель").font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 8)
                }
                Section("Дискография") {
                    Button {
                        artistOpen = false
                        playerOpen = true
                    } label: {
                        HStack(spacing: 12) {
                            Artwork(size: 48, accent: accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.title).foregroundStyle(.primary)
                                Text("Традиционная песня").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.fill").foregroundStyle(accent)
                        }
                    }
                }
            }
            .navigationTitle(track.artist)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Готово") { artistOpen = false } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func startLiveActivity() {
        Task { await RhythmActivityController.start(trackTitle: track.title, artist: track.artist) }
    }

    private func endLiveActivity() {
        Task { await RhythmActivityController.endAll() }
    }

    private func timeLabel(_ seconds: Double) -> String {
        let value = seconds.isFinite ? max(0, Int(seconds)) : 0
        return String(format: "%d:%02d", value / 60, value % 60)
    }

    private func playerControl(_ icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(ink)
                .frame(width: 38, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func playerModeButton(_ icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(selected ? accent : muted)
                .frame(width: 30, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func togglePlayback() {
        if player == nil { player = AVPlayer(url: track.audioURL) }
        if isPlaying {
            player?.pause()
            isPlaying = false
            endLiveActivity()
        } else {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch { print("Audio session setup failed: \\(error)") }
            player?.play()
            isPlaying = true
            startLiveActivity()
        }
    }

    private func refreshWave() {
        withAnimation(.spring(duration: 0.4)) {
            wave = [.sample].shuffled()
            waveIndex = 0
        }
    }

    private func title(_ text: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(text).font(.system(size: 30, weight: .bold, design: .rounded)).tracking(-0.7)
            Text(subtitle).font(.system(size: 13)).foregroundStyle(muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func section(_ text: String) -> some View {
        Text(text.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.4).foregroundStyle(muted)
    }

    private func choice(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selected ? (dark ? .black : .white) : ink)
                .frame(maxWidth: .infinity).padding(14)
                .background(selected ? accent : panel, in: RoundedRectangle(cornerRadius: 15))
        }.buttonStyle(.plain)
    }

    private func accentChoice(_ text: String, color: Color) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { accentName = text } } label: {
            VStack(spacing: 7) {
                Circle().fill(color).frame(width: 27, height: 27)
                    .overlay(Circle().stroke(ink.opacity(accentName == text ? 0.7 : 0), lineWidth: 2).padding(-4))
                Text(text).font(.system(size: 9, weight: .medium)).foregroundStyle(ink)
            }.frame(maxWidth: .infinity).padding(10).background(panel, in: RoundedRectangle(cornerRadius: 15))
        }.buttonStyle(.plain)
    }
}

private struct RhythmMark: View {
    let color: Color
    let size: CGFloat
    var body: some View {
        HStack(spacing: size * 0.09) {
            Capsule().frame(width: size * 0.09, height: size * 0.29)
            Capsule().frame(width: size * 0.09, height: size * 0.53)
            Capsule().frame(width: size * 0.09, height: size * 0.75)
            Capsule().frame(width: size * 0.09, height: size * 0.43)
            Capsule().frame(width: size * 0.09, height: size * 0.22)
        }
        .foregroundStyle(color).frame(width: size, height: size)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: size * 0.28))
        .overlay(RoundedRectangle(cornerRadius: size * 0.28).stroke(color.opacity(0.24)))
        .shadow(color: color.opacity(0.16), radius: 12)
    }
}

private struct Artwork: View {
    let size: CGFloat
    let accent: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.16)
                .fill(LinearGradient(colors: [accent.opacity(0.95), .indigo.opacity(0.8), .black], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(.white.opacity(0.27), lineWidth: 1).frame(width: size * 0.74)
            Circle().stroke(.white.opacity(0.18), lineWidth: 1).frame(width: size * 0.52)
            Image(systemName: "waveform").font(.system(size: size * 0.23, weight: .light)).foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 9)
            VStack {
                Spacer()
                HStack {
                    Text("R").font(.system(size: size * 0.075, weight: .bold, design: .rounded)).tracking(2)
                    Spacer()
                    Image(systemName: "circle.hexagongrid.fill")
                }.font(.system(size: size * 0.07)).foregroundStyle(.white.opacity(0.65)).padding(size * 0.08)
            }
        }
        .frame(width: size, height: size).clipShape(RoundedRectangle(cornerRadius: size * 0.16))
        .overlay(RoundedRectangle(cornerRadius: size * 0.16).stroke(.white.opacity(0.14)))
    }
}
