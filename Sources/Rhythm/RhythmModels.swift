import Foundation

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


struct LyricLine: Identifiable, Codable, Hashable {
    let id: Int
    let start: TimeInterval
    let text: String
}

enum ArtworkTone: String, CaseIterable, Codable, Hashable {
    case glacier, ember, orchid, moss, cobalt, amber, rose, graphite
}

struct Track: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let artist: String
    let artistID: String
    let album: String
    let duration: TimeInterval
    let tags: [String]
    let tone: ArtworkTone
    let lyrics: [LyricLine]
}

struct ArtistProfile: Identifiable, Hashable {
    let id: String
    let name: String
    let note: String
    let tone: ArtworkTone
}

struct RhythmPlaylist: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var trackIDs: [String]
    var tone: ArtworkTone
}

enum DemoCatalog {
    static let tracks: [Track] = [
        Track(id: "north-route", title: "Ночной маршрут", artist: "Север", artistID: "sever", album: "Город не спит", duration: 218, tags: ["Ночь", "Фокус", "Электроника"], tone: .glacier, lyrics: [
            LyricLine(id: 0, start: 0, text: "Город медленно зажигает огни"),
            LyricLine(id: 1, start: 28, text: "И наш маршрут растворяется вдали"),
            LyricLine(id: 2, start: 62, text: "Тише шаг, ближе звук"),
            LyricLine(id: 3, start: 96, text: "Ночь оставит этот ритм для нас")
        ]),
        Track(id: "warm-rain", title: "Тёплый дождь", artist: "Лея", artistID: "leya", album: "Между строк", duration: 196, tags: ["Спокойствие", "Инди", "Вечер"], tone: .orchid, lyrics: [
            LyricLine(id: 0, start: 0, text: "На ладонях тает тёплый дождь"),
            LyricLine(id: 1, start: 31, text: "В окнах отражается апрель"),
            LyricLine(id: 2, start: 66, text: "Если ты сегодня не уснёшь"),
            LyricLine(id: 3, start: 102, text: "Мы найдём дорогу из теней")
        ]),
        Track(id: "afterglow", title: "После полуночи", artist: "Тихий район", artistID: "quiet-district", album: "Сторона B", duration: 231, tags: ["Ночь", "Спокойствие", "Электроника"], tone: .cobalt, lyrics: [
            LyricLine(id: 0, start: 0, text: "После полуночи легче дышать"),
            LyricLine(id: 1, start: 35, text: "Улицы учатся не спешить"),
            LyricLine(id: 2, start: 70, text: "Можно не знать, куда дальше бежать"),
            LyricLine(id: 3, start: 108, text: "Можно остаться и просто быть")
        ]),
        Track(id: "thin-line", title: "Тонкая грань", artist: "Эфир", artistID: "ether", album: "Контур", duration: 204, tags: ["Фокус", "Электроника", "Энергия"], tone: .glacier, lyrics: [
            LyricLine(id: 0, start: 0, text: "Между нами тонкая грань"),
            LyricLine(id: 1, start: 27, text: "За которой меняется свет"),
            LyricLine(id: 2, start: 61, text: "Не теряй и не обещай"),
            LyricLine(id: 3, start: 94, text: "У этой ночи названия нет")
        ]),
        Track(id: "city-speaks", title: "Город говорит", artist: "Кедр", artistID: "cedar", album: "Высота", duration: 187, tags: ["Энергия", "Инди", "Утро"], tone: .ember, lyrics: [
            LyricLine(id: 0, start: 0, text: "Город говорит на своём языке"),
            LyricLine(id: 1, start: 26, text: "Мы читаем его на ходу"),
            LyricLine(id: 2, start: 58, text: "Каждый новый поворот вдалеке"),
            LyricLine(id: 3, start: 91, text: "Обещает другую высоту")
        ]),
        Track(id: "shoreline", title: "Дальше от берега", artist: "Юна", artistID: "yuna", album: "Вода и воздух", duration: 244, tags: ["Спокойствие", "Инди", "Вечер"], tone: .moss, lyrics: [
            LyricLine(id: 0, start: 0, text: "Дальше от берега, ближе к тебе"),
            LyricLine(id: 1, start: 38, text: "Ветер раскладывает облака"),
            LyricLine(id: 2, start: 78, text: "Мы оставляем волну на воде"),
            LyricLine(id: 3, start: 119, text: "И отпускаем её на века")
        ]),
        Track(id: "blue-hour", title: "Синий час", artist: "Север", artistID: "sever", album: "Город не спит", duration: 212, tags: ["Ночь", "Фокус", "Инди"], tone: .cobalt, lyrics: [
            LyricLine(id: 0, start: 0, text: "Синий час между сном и огнём"),
            LyricLine(id: 1, start: 30, text: "Небо меняет привычный оттенок"),
            LyricLine(id: 2, start: 64, text: "Мы этот город с тобой узнаём"),
            LyricLine(id: 3, start: 99, text: "По тихим следам на ладонях")
        ]),
        Track(id: "first-train", title: "Первый поезд", artist: "Кедр", artistID: "cedar", album: "Высота", duration: 199, tags: ["Энергия", "Утро", "Фокус"], tone: .amber, lyrics: [
            LyricLine(id: 0, start: 0, text: "Первый поезд разбудит район"),
            LyricLine(id: 1, start: 29, text: "Мы успеем поймать этот свет"),
            LyricLine(id: 2, start: 63, text: "Каждый новый маршрут — горизонт"),
            LyricLine(id: 3, start: 97, text: "Каждый шаг оставляет ответ")
        ]),
        Track(id: "paper-sky", title: "Бумажное небо", artist: "Лея", artistID: "leya", album: "Между строк", duration: 221, tags: ["Спокойствие", "Инди", "Фокус"], tone: .rose, lyrics: [
            LyricLine(id: 0, start: 0, text: "Бумажное небо плывёт над водой"),
            LyricLine(id: 1, start: 34, text: "Тонкие линии держат рассвет"),
            LyricLine(id: 2, start: 72, text: "Я сохраню эту тишину"),
            LyricLine(id: 3, start: 110, text: "Чтобы однажды вернуться в неё")
        ]),
        Track(id: "deep-current", title: "Течение", artist: "Эфир", artistID: "ether", album: "Контур", duration: 208, tags: ["Энергия", "Электроника", "Ночь"], tone: .graphite, lyrics: [
            LyricLine(id: 0, start: 0, text: "Течение знает, где спрятан причал"),
            LyricLine(id: 1, start: 30, text: "Мы не считаем шаги до утра"),
            LyricLine(id: 2, start: 67, text: "Каждый сигнал что-то нам обещал"),
            LyricLine(id: 3, start: 102, text: "Каждая пауза тоже игра")
        ]),
        Track(id: "slow-orbit", title: "Медленная орбита", artist: "Юна", artistID: "yuna", album: "Вода и воздух", duration: 236, tags: ["Спокойствие", "Ночь", "Вечер"], tone: .orchid, lyrics: [
            LyricLine(id: 0, start: 0, text: "Медленная орбита вокруг тишины"),
            LyricLine(id: 1, start: 36, text: "Свет отдаляется, но не погас"),
            LyricLine(id: 2, start: 76, text: "Всё, что мы ищем, уже сохранено"),
            LyricLine(id: 3, start: 118, text: "В движении света и в каждом из нас")
        ]),
        Track(id: "red-signal", title: "Красный сигнал", artist: "Тихий район", artistID: "quiet-district", album: "Сторона B", duration: 193, tags: ["Энергия", "Ночь", "Электроника"], tone: .ember, lyrics: [
            LyricLine(id: 0, start: 0, text: "Красный сигнал на пустой полосе"),
            LyricLine(id: 1, start: 28, text: "Город на миг задержал дыхание"),
            LyricLine(id: 2, start: 59, text: "Мы растворяемся в этой грозе"),
            LyricLine(id: 3, start: 91, text: "И не боимся нового знания")
        ])
    ]

    static let artists: [ArtistProfile] = [
        ArtistProfile(id: "sever", name: "Север", note: "Демо-проект · электроника и ночные маршруты", tone: .glacier),
        ArtistProfile(id: "leya", name: "Лея", note: "Демо-проект · мягкий инди-поп", tone: .orchid),
        ArtistProfile(id: "quiet-district", name: "Тихий район", note: "Демо-проект · музыка для поздних часов", tone: .cobalt),
        ArtistProfile(id: "ether", name: "Эфир", note: "Демо-проект · электронные текстуры", tone: .graphite),
        ArtistProfile(id: "cedar", name: "Кедр", note: "Демо-проект · гитары и движение", tone: .ember),
        ArtistProfile(id: "yuna", name: "Юна", note: "Демо-проект · спокойные истории", tone: .moss)
    ]

    static func artist(id: String) -> ArtistProfile? {
        artists.first { $0.id == id }
    }
}
