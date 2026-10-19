import Foundation

struct LyricsLine: Identifiable, Codable {
    let id: UUID
    let time: TimeInterval
    let text: String
    
    init(time: TimeInterval, text: String) {
        self.id = UUID()
        self.time = time
        self.text = text
    }
    
    enum CodingKeys: String, CodingKey {
        case time, text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.time = try container.decode(TimeInterval.self, forKey: .time)
        self.text = try container.decode(String.self, forKey: .text)
    }
}

struct Lyrics: Codable {
    let trackId: String
    let lines: [LyricsLine]?
    let plainText: String?
    let synced: Bool
    
    var isSynced: Bool { synced && lines != nil && !(lines?.isEmpty ?? true) }
    
    enum CodingKeys: String, CodingKey {
        case lines, synced
        case trackId = "trackId"
        case plainText = "plainText"
    }
}
