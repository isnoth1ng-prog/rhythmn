import Foundation

struct Album: Identifiable, Codable {
    let id: String
    let title: String
    let artistName: String
    let thumbnailUrl: String
    let year: String?
    var tracks: [Track]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, year, tracks
        case artistName = "artistName"
        case thumbnailUrl = "thumbnailUrl"
    }
}
