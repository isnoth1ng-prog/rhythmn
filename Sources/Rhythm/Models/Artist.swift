import Foundation

struct Artist: Identifiable, Codable {
    let id: String
    let name: String
    let imageUrl: String
    let subscriberCount: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case imageUrl = "imageUrl"
        case subscriberCount = "subscriberCount"
    }
}
