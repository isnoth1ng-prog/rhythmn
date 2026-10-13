import SwiftUI
import AVFoundation

private struct Track: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let genre: String
    let audioURL: URL
    static let sample = Track(
        id: "saints-pd",
        title: "When the Saints Go Marching In",
        artist: "Traditional · public domain recording",
        genre: "Folk",
        audioURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/transcoded/2/2b/When_the_Saints_Go_Marching_In.ogg/When_the_Saints_Go_Marching_In.ogg.mp3")!
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
    @State private var lyricsVisible = true
    @State private var isPlaying = false
    @State private var player: AVPlayer?
    @State private var wave: [Track] = [.sample]
    @State private var waveIndex = 0

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
            VStack(spacing: 0) {
                header
                Group {
                    switch tab {
                    case .library: library
                    case .search: search
                    case .wave: waveView
                    case .settings: settings
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                miniPlayer
                tabBar
            }
        }
        .foregroundStyle(ink)
        .preferredColorScheme(dark ? .dark : .light)
        .statusBarHidden(false)
        .fullScreenCover(isPresented: $playerOpen) { fullPlayer }
        .onDisappear { player?.pause() }
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                title("Моя музыка", subtitle: "Треки, к которым хочется вернуться")
                Text(saved ? "СОХРАНЕНО" : "ТЕСТОВЫЙ ТРЕК")
                    .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.5).foregroundStyle(muted)
                trackRow(.sample)
                Text("Запись мелодии находится в общественном достоянии. Источник: Wikimedia Commons.")
                    .font(.system(size: 11)).foregroundStyle(muted)
            }.padding(20)
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
        Button { playerOpen = true } label: {
            HStack(spacing: 12) {
                Artwork(size: 42, accent: accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    Text(track.artist).font(.system(size: 10)).foregroundStyle(muted).lineLimit(1)
                }
                Spacer()
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .bold)).foregroundStyle(accent).frame(width: 42, height: 42)
                }.buttonStyle(.plain)
            }
            .padding(10).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(ink.opacity(0.08)))
            .padding(.horizontal, 14).padding(.top, 7).padding(.bottom, 6)
        }.buttonStyle(.plain)
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
        ZStack {
            background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { playerOpen = false } label: {
                        Image(systemName: "chevron.down").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(ink).frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("СЕЙЧАС ИГРАЕТ").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.5).foregroundStyle(muted)
                    Spacer()
                    Image(systemName: "ellipsis").foregroundStyle(ink).frame(width: 44, height: 44)
                }.padding(.horizontal, 16)
                ScrollView {
                    VStack(spacing: 21) {
                        Artwork(size: 280, accent: accent)
                            .shadow(color: accent.opacity(0.2), radius: 32, y: 16).padding(.top, 17)
                        VStack(spacing: 7) {
                            Text(track.title).font(.system(size: 23, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
                            Text(track.artist).font(.system(size: 13)).foregroundStyle(accent)
                        }
                        HStack(spacing: 28) {
                            Image(systemName: "shuffle").foregroundStyle(muted)
                            Image(systemName: "backward.end.fill").font(.system(size: 23))
                            Button(action: togglePlayback) {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 23, weight: .bold)).foregroundStyle(dark ? .black : .white)
                                    .frame(width: 66, height: 66).background(accent, in: Circle())
                            }
                            Image(systemName: "forward.end.fill").font(.system(size: 23))
                            Image(systemName: "repeat").foregroundStyle(muted)
                        }.buttonStyle(.plain)
                        HStack {
                            Button { saved.toggle() } label: {
                                Label(saved ? "В библиотеке" : "Сохранить", systemImage: saved ? "checkmark" : "plus")
                            }
                            Spacer()
                            Button { withAnimation(.spring(duration: 0.35)) { lyricsVisible.toggle() } } label: {
                                Label(lyricsVisible ? "Скрыть текст" : "Текст", systemImage: "quote.bubble")
                            }
                        }
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(accent)
                        if lyricsVisible {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("ТЕКСТ ДЛЯ ПРОВЕРКИ").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.5).foregroundStyle(muted)
                                Text("Ночь зажигает огни,")
                                Text("Город ловит новый ритм,")
                                Text("Мы плывём за тёплым светом,")
                                Text("Пока музыка звучит.")
                                    .foregroundStyle(accent)
                            }
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18).background(panel, in: RoundedRectangle(cornerRadius: 20))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        Text("Запись: Wikimedia Commons · public domain. Текст выше написан для Rhythm и не является текстом этой инструментальной записи.")
                            .font(.system(size: 10)).foregroundStyle(muted).frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(.horizontal, 23).padding(.bottom, 26)
                }
            }
        }
        .preferredColorScheme(dark ? .dark : .light)
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

    private func togglePlayback() {
        if player == nil { player = AVPlayer(url: track.audioURL) }
        if isPlaying { player?.pause() } else { player?.play() }
        isPlaying.toggle()
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
