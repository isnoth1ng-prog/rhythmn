import SwiftUI

private struct Track: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let genre: String
    let duration: Int
    let colors: [Color]

    static let demo: [Track] = [
        Track(id: "north", title: "Ночной маршрут", artist: "север", album: "после огней", genre: "электроника", duration: 198, colors: [.cyan, .indigo]),
        Track(id: "glass", title: "Стеклянный город", artist: "комната 04", album: "неон", genre: "инди", duration: 221, colors: [.purple, .pink]),
        Track(id: "rain", title: "Пока идёт дождь", artist: "линия сна", album: "пауза", genre: "инди", duration: 184, colors: [.blue, .teal]),
        Track(id: "pulse", title: "Пульс", artist: "пустой этаж", album: "частота", genre: "электроника", duration: 207, colors: [.orange, .red]),
        Track(id: "home", title: "Ближе к дому", artist: "медленный свет", album: "в пути", genre: "поп", duration: 193, colors: [.mint, .blue]),
        Track(id: "snow", title: "Снег на проводах", artist: "белый шум", album: "снаружи", genre: "альтернатива", duration: 232, colors: [.gray, .indigo])
    ]
}

private enum AppTab: String, CaseIterable, Identifiable {
    case library = "Моя музыка"
    case search = "Поиск"
    case player = "Плеер"
    case wave = "Моя волна"
    case settings = "Тема"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .library: "square.stack"
        case .search: "magnifyingglass"
        case .player: "waveform"
        case .wave: "sparkles"
        case .settings: "circle.lefthalf.filled"
        }
    }
}

struct ContentView: View {
    @AppStorage("rhythm.savedTracks") private var savedTracks = ""
    @AppStorage("rhythm.playCounts") private var playCounts = ""
    @AppStorage("rhythm.accent") private var accentName = "Мята"
    @State private var tab: AppTab = .library
    @State private var currentTrackID = Track.demo[0].id
    @State private var searchText = ""
    @State private var isPlaying = false
    @State private var isShuffled = false
    @State private var repeatsTrack = false
    @State private var progress = 0.28
    @State private var artistPage: String?
    @State private var showingLyrics = false

    private var currentTrack: Track {
        Track.demo.first(where: { $0.id == currentTrackID }) ?? Track.demo[0]
    }
    private var savedIDs: Set<String> {
        Set(savedTracks.split(separator: ",").map(String.init))
    }
    private var accent: Color {
        switch accentName {
        case "Фиолетовый": .purple
        case "Янтарный": .orange
        case "Ледяной": .cyan
        default: Color(red: 0.45, green: 0.95, blue: 0.77)
        }
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                brandHeader
                Group {
                    if let artistPage {
                        artistScreen(artistPage)
                    } else {
                        mainScreen
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if tab != .player && artistPage == nil {
                    miniPlayer
                }
                tabBar
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingLyrics) {
            lyricsSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: searchText) { _, value in
            if !value.trimmingCharacters(in: .whitespaces).isEmpty {
                recordPlayEvent(for: currentTrackID, increment: false)
            }
        }
    }

    private var background: some View {
        ZStack {
            Color(red: 0.035, green: 0.045, blue: 0.055)
            RadialGradient(colors: [accent.opacity(0.16), .clear], center: .topTrailing, startRadius: 10, endRadius: 420)
            LinearGradient(colors: [.white.opacity(0.035), .clear, accent.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .ignoresSafeArea()
    }

    private var brandHeader: some View {
        HStack(spacing: 10) {
            RhythmMark(color: accent, size: 31)
            Text("RHYTHM")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(3.2)
            Spacer()
            Text("ДЕМО-КАТАЛОГ")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(1.3)
                .foregroundStyle(.white.opacity(0.43))
            Circle().fill(accent).frame(width: 5, height: 5)
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 13)
    }

    @ViewBuilder private var mainScreen: some View {
        switch tab {
        case .library: libraryScreen
        case .search: searchScreen
        case .player: playerScreen
        case .wave: waveScreen
        case .settings: settingsScreen
        }
    }

    private var libraryScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                pageTitle("Моя музыка", subtitle: "Твоя библиотека — в твоём ритме")
                HStack(spacing: 12) {
                    statCard(value: "\(savedIDs.count)", label: "Сохранено", symbol: "bookmark.fill")
                    statCard(value: "\(Track.demo.count)", label: "В каталоге", symbol: "waveform")
                }
                sectionHeading("Сохранённое", trailing: savedIDs.isEmpty ? "добавляй кнопкой ＋" : nil)
                if savedIDs.isEmpty {
                    emptyCard(symbol: "square.stack.3d.up", title: "Здесь будет твоя музыка", message: "Нажми ＋ у трека, чтобы сохранить его в библиотеку.")
                } else {
                    ForEach(Track.demo.filter { savedIDs.contains($0.id) }) { track in
                        trackRow(track)
                    }
                }
                sectionHeading("Недавно слушали", trailing: "демо")
                ForEach(Array(Track.demo.prefix(3))) { track in
                    trackRow(track)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 13)
            .padding(.bottom, 20)
        }
    }

    private var searchScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("Поиск", subtitle: "Находи треки и новых авторов")
                HStack(spacing: 11) {
                    Image(systemName: "magnifyingglass").foregroundStyle(accent)
                    TextField("Название или автор", text: $searchText)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.45))
                        }
                    }
                }
                .padding(16)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08)))
                sectionHeading(searchText.isEmpty ? "Можно начать с этого" : "Результаты", trailing: "демо")
                let results = Track.demo.filter {
                    searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) || $0.artist.localizedCaseInsensitiveContains(searchText)
                }
                if results.isEmpty {
                    emptyCard(symbol: "sparkle.magnifyingglass", title: "Пока ничего", message: "В демо-каталоге такого трека нет. Подключение музыкального источника — следующий этап.")
                } else {
                    ForEach(results) { track in trackRow(track) }
                }
                Text("Сейчас показан только пример интерфейса. Это не поиск по реальным музыкальным сервисам.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.38))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 13)
            .padding(.bottom, 20)
        }
    }

    private var playerScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HStack {
                    Text("СЕЙЧАС ИГРАЕТ")
                    Spacer()
                    Text("ПРОТОТИП")
                }
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(1.8)
                .foregroundStyle(.white.opacity(0.44))

                Artwork(track: currentTrack, size: 292)
                    .shadow(color: currentTrack.colors.first?.opacity(0.28) ?? accent.opacity(0.2), radius: 34, y: 18)
                    .padding(.top, 2)

                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentTrack.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Button { artistPage = currentTrack.artist } label: {
                            HStack(spacing: 5) {
                                Text(currentTrack.artist)
                                Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .bold))
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(accent)
                        }
                    }
                    Spacer()
                    libraryButton(for: currentTrack, large: true)
                }

                VStack(spacing: 8) {
                    Slider(value: $progress, in: 0...1)
                        .tint(accent)
                    HStack {
                        Text(timeString(Int(Double(currentTrack.duration) * progress)))
                        Spacer()
                        Text("−" + timeString(Int(Double(currentTrack.duration) * (1 - progress))))
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                }

                HStack(spacing: 0) {
                    Button { isShuffled.toggle() } label: {
                        Image(systemName: "shuffle").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isShuffled ? accent : .white.opacity(0.55))
                    }
                    Spacer()
                    Button { changeTrack(-1) } label: {
                        Image(systemName: "backward.end.fill").font(.system(size: 24))
                    }
                    Spacer()
                    Button { isPlaying.toggle() } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 25, weight: .bold))
                            .contentTransition(.symbolEffect(.replace))
                            .foregroundStyle(.black)
                            .frame(width: 66, height: 66)
                            .background(accent, in: Circle())
                    }
                    Spacer()
                    Button { changeTrack(1) } label: {
                        Image(systemName: "forward.end.fill").font(.system(size: 24))
                    }
                    Spacer()
                    Button { repeatsTrack.toggle() } label: {
                        Image(systemName: repeatsTrack ? "repeat.1" : "repeat").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(repeatsTrack ? accent : .white.opacity(0.55))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)

                Button { showingLyrics = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "quote.bubble")
                        Text("Открыть текст песни")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 17))
                    .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.08)))
                }
                Text("Демонстрация управления. Реальный звук появится после подключения источника музыки.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.37))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 22)
            .padding(.top, 13)
            .padding(.bottom, 24)
        }
    }

    private var waveScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 21) {
                pageTitle("Моя волна", subtitle: "Подбираем музыку под тебя")
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 27)
                        .fill(LinearGradient(colors: [accent.opacity(0.36), .purple.opacity(0.26), .white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Circle().fill(accent.opacity(0.17)).frame(width: 170).blur(radius: 30).offset(x: 210, y: -25)
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "waveform.path").font(.system(size: 27, weight: .light)).foregroundStyle(accent)
                        Text(savedIDs.isEmpty ? "Волна начинается с тебя" : "Мы уловили твой ритм")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                        Text(savedIDs.isEmpty ? "Сохрани несколько треков — и рекомендации станут личными." : "Подборка учитывает твои сохранения и прослушивания.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(22)
                }
                .frame(height: 165)
                .clipShape(RoundedRectangle(cornerRadius: 27))
                sectionHeading("Для тебя", trailing: "обновляется по вкусам")
                ForEach(recommendedTracks) { track in trackRow(track) }
                Text("Пока рекомендации рассчитаны на устройстве по демо-данным: сохранениям и истории. Онлайн-каталог подключим отдельно.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.38))
            }
            .padding(.horizontal, 20)
            .padding(.top, 13)
            .padding(.bottom, 20)
        }
    }

    private var recommendedTracks: [Track] {
        let favoriteGenres = Track.demo.filter { savedIDs.contains($0.id) }.map(\.genre)
        if favoriteGenres.isEmpty { return Track.demo.shuffled().prefix(4).sorted { $0.title < $1.title } }
        return Track.demo.sorted {
            let left = favoriteGenres.filter { $0 == $0 }.count
            let right = favoriteGenres.filter { $0 == $1.genre }.count
            return left > right
        }.filter { !savedIDs.contains($0.id) }.prefix(4).map { $0 }
    }

    private var settingsScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                pageTitle("Внешний вид", subtitle: "Настрой Rhythm под себя")
                sectionHeading("Цвет акцента", trailing: accentName)
                VStack(spacing: 12) {
                    accentOption("Мята", color: Color(red: 0.45, green: 0.95, blue: 0.77))
                    accentOption("Фиолетовый", color: .purple)
                    accentOption("Янтарный", color: .orange)
                    accentOption("Ледяной", color: .cyan)
                }
                sectionHeading("Оформление")
                HStack(spacing: 14) {
                    Image(systemName: "moon.stars.fill").foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Тёмное стекло").font(.system(size: 15, weight: .semibold))
                        Text("Матовые поверхности и мягкий свет").font(.system(size: 12)).foregroundStyle(.white.opacity(0.48))
                    }
                    Spacer()
                    Text("ВКЛ").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(accent)
                }
                .padding(16)
                .glassCard()
                sectionHeading("О приложении")
                Text("Rhythm — ранний прототип. Музыкальные источники, тексты песен и публикация появятся после проверки доступности и прав.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(16)
                    .glassCard()
            }
            .padding(.horizontal, 20)
            .padding(.top, 13)
            .padding(.bottom, 20)
        }
    }

    private func artistScreen(_ artist: String) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Button { artistPage = nil } label: {
                    Label("Назад", systemImage: "chevron.left")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(accent)
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 26).fill(LinearGradient(colors: [accent.opacity(0.4), .purple.opacity(0.25), .white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    VStack(spacing: 10) {
                        RhythmMark(color: accent, size: 58)
                        Text(artist).font(.system(size: 27, weight: .bold, design: .rounded))
                        Text("СТРАНИЦА АВТОРА · ДЕМО").font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1.4).foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(height: 190)
                sectionHeading("Дискография", trailing: "пример")
                ForEach(Track.demo.filter { $0.artist == artist }) { track in trackRow(track) }
                Text("Полная дискография появится вместе с подключением официального музыкального каталога.")
                    .font(.system(size: 12)).foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 20).padding(.top, 13).padding(.bottom, 20)
        }
    }

    private var lyricsSheet: some View {
        ZStack {
            background
            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentTrack.title).font(.system(size: 17, weight: .bold))
                        Text(currentTrack.artist).font(.system(size: 13)).foregroundStyle(accent)
                    }
                    Spacer()
                    Button { showingLyrics = false } label: {
                        Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white.opacity(0.7))
                            .frame(width: 34, height: 34).background(.white.opacity(0.09), in: Circle())
                    }
                }
                .padding(.top, 20)
                Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                Spacer()
                VStack(alignment: .leading, spacing: 19) {
                    Text("Город укрывает огни")
                    Text("И ночь плывёт по проводам")
                        .foregroundStyle(accent)
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Text("Мы выбираем свой маршрут")
                    Text("Пока звучит внутри волна")
                        .foregroundStyle(.white.opacity(0.38))
                }
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Label("Демо-строки · не текст реальной песни", systemImage: "info.circle")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.4))
                Slider(value: $progress, in: 0...1).tint(accent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }

    private var miniPlayer: some View {
        Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) { tab = .player }
        } label: {
            HStack(spacing: 12) {
                Artwork(track: currentTrack, size: 43)
                VStack(alignment: .leading, spacing: 3) {
                    Text(currentTrack.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    Text(currentTrack.artist).font(.system(size: 11)).foregroundStyle(.white.opacity(0.52))
                }
                Spacer()
                Button { isPlaying.toggle() } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(accent).frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(.ultraThinMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.09)))
            .padding(.horizontal, 15)
            .padding(.top, 8)
            .padding(.bottom, 7)
        }
        .buttonStyle(.plain)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { item in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        tab = item
                        artistPage = nil
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 17, weight: tab == item ? .semibold : .regular))
                            .symbolEffect(.bounce, value: tab == item)
                        Text(item.rawValue)
                            .font(.system(size: 8, weight: tab == item ? .semibold : .regular))
                            .lineLimit(1).minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(tab == item ? accent : .white.opacity(0.46))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 5)
        .background(.ultraThinMaterial.opacity(0.9))
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.07)).frame(height: 0.5) }
    }

    private var lyricsLines: [String] {
        ["Город укрывает огни", "И ночь плывёт по проводам", "Мы выбираем свой маршрут", "Пока звучит внутри волна"]
    }

    private var recommendedDummy: [Track] { Track.demo }

    private func pageTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 30, weight: .bold, design: .rounded)).tracking(-0.7)
            Text(subtitle).font(.system(size: 13)).foregroundStyle(.white.opacity(0.48))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeading(_ title: String, trailing: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(size: 17, weight: .bold, design: .rounded))
            Spacer()
            if let trailing {
                Text(trailing.uppercased()).font(.system(size: 8, weight: .semibold, design: .monospaced)).tracking(0.8).foregroundStyle(.white.opacity(0.36))
            }
        }
    }

    private func statCard(value: String, label: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 14)).foregroundStyle(accent)
                .frame(width: 35, height: 35).background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(value).font(.system(size: 20, weight: .bold, design: .rounded))
                Text(label).font(.system(size: 10)).foregroundStyle(.white.opacity(0.46))
            }
            Spacer(minLength: 0)
        }
        .padding(13).frame(maxWidth: .infinity, alignment: .leading).glassCard()
    }

    private func emptyCard(symbol: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 26, weight: .light)).foregroundStyle(accent.opacity(0.9))
            Text(title).font(.system(size: 15, weight: .semibold))
            Text(message).font(.system(size: 12)).foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 23).padding(.horizontal, 18).glassCard()
    }

    private func trackRow(_ track: Track) -> some View {
        HStack(spacing: 12) {
            Button { select(track) } label: {
                HStack(spacing: 12) {
                    Artwork(track: track, size: 52)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(track.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                        Button { artistPage = track.artist } label: {
                            Text(track.artist).font(.system(size: 11)).foregroundStyle(accent.opacity(0.88))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 2)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            libraryButton(for: track)
        }
        .padding(9)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 17))
    }

    private func libraryButton(for track: Track, large: Bool = false) -> some View {
        let isSaved = savedIDs.contains(track.id)
        return Button { toggleSaved(track) } label: {
            Image(systemName: isSaved ? "checkmark" : "plus")
                .font(.system(size: large ? 16 : 13, weight: .semibold))
                .foregroundStyle(isSaved ? accent : .white.opacity(0.68))
                .frame(width: large ? 43 : 36, height: large ? 43 : 36)
                .background(isSaved ? accent.opacity(0.12) : .white.opacity(0.07), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? "Убрать из библиотеки" : "Добавить в библиотеку")
    }

    private func accentOption(_ name: String, color: Color) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { accentName = name } } label: {
            HStack(spacing: 12) {
                Circle().fill(color).frame(width: 21, height: 21).shadow(color: color.opacity(0.4), radius: 9)
                Text(name).font(.system(size: 14, weight: .medium)).foregroundStyle(.white)
                Spacer()
                if accentName == name { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(color) }
            }
            .padding(15).glassCard()
        }
        .buttonStyle(.plain)
    }

    private func select(_ track: Track) {
        currentTrackID = track.id
        progress = 0
        isPlaying = true
        recordPlayEvent(for: track.id, increment: true)
        tab = .player
    }

    private func changeTrack(_ direction: Int) {
        let tracks = Track.demo
        let index = tracks.firstIndex(where: { $0.id == currentTrackID }) ?? 0
        let next = (index + direction + tracks.count) % tracks.count
        select(tracks[next])
    }

    private func toggleSaved(_ track: Track) {
        var ids = savedIDs
        if ids.contains(track.id) { ids.remove(track.id) } else { ids.insert(track.id) }
        savedTracks = ids.sorted().joined(separator: ",")
    }

    private func recordPlayEvent(for id: String, increment: Bool) {
        guard increment else { return }
        var counts = Dictionary(uniqueKeysWithValues: playCounts.split(separator: ",").compactMap { entry -> (String, Int)? in
            let pair = entry.split(separator: ":", maxSplits: 1)
            guard pair.count == 2, let count = Int(pair[1]) else { return nil }
            return (String(pair[0]), count)
        })
        counts[id, default: 0] += 1
        playCounts = counts.map { "\($0.key):\($0.value)" }.sorted().joined(separator: ",")
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", max(0, seconds) / 60, max(0, seconds) % 60)
    }
}

private struct RhythmMark: View {
    let color: Color
    var size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.34)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: size * 0.34).stroke(.white.opacity(0.17)))
            HStack(alignment: .center, spacing: size * 0.08) {
                Capsule().frame(width: size * 0.08, height: size * 0.26)
                Capsule().frame(width: size * 0.08, height: size * 0.48)
                Capsule().frame(width: size * 0.08, height: size * 0.68)
                Capsule().frame(width: size * 0.08, height: size * 0.37)
                Capsule().frame(width: size * 0.08, height: size * 0.19)
            }
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.7), radius: 8)
        }
        .frame(width: size, height: size)
    }
}

private struct Artwork: View {
    let track: Track
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.16)
                .fill(LinearGradient(colors: track.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(.white.opacity(0.2), lineWidth: size * 0.002).frame(width: size * 0.74)
            Circle().stroke(.white.opacity(0.13), lineWidth: size * 0.002).frame(width: size * 0.52)
            Circle().fill(.white.opacity(0.1)).frame(width: size * 0.3)
                .background(.ultraThinMaterial, in: Circle())
            Image(systemName: "waveform").font(.system(size: size * 0.21, weight: .light))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.22), radius: 7)
            VStack {
                Spacer()
                HStack {
                    Text("R").font(.system(size: size * 0.07, weight: .bold, design: .rounded)).tracking(1)
                    Spacer()
                    Image(systemName: "circle.hexagongrid.fill").font(.system(size: size * 0.075))
                }
                .foregroundStyle(.white.opacity(0.6))
                .padding(size * 0.085)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.16))
        .overlay(RoundedRectangle(cornerRadius: size * 0.16).stroke(.white.opacity(0.13)))
    }
}

private extension View {
    func glassCard() -> some View {
        background(.ultraThinMaterial.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08)))
    }
}
