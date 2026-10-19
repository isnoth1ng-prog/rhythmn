import Foundation

struct Track: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let artist: String
    let artistId: String
    let albumTitle: String?
    let thumbnailUrl: String
    let duration: TimeInterval
    var streamUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, artist, duration
        case artistId = "artistId"
        case albumTitle = "albumTitle"
        case thumbnailUrl = "thumbnailUrl"
        case streamUrl = "streamUrl"
    }
    
    static func == (lhs: Track, rhs: Track) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
