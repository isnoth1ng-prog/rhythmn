import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class APIService {
    static let shared = APIService()
    
    var baseURL: String {
        get {
            UserDefaults.standard.string(forKey: "custom_backend_url") ?? "http://localhost:8000/api"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "custom_backend_url")
        }
    }
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }
    
    // MARK: - Search
    
    func searchTracks(query: String) async throws -> [Track] {
        let items = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "tracks")
        ]
        let response: SearchResponse = try await get("/search", queryItems: items)
        return response.tracks ?? []
    }
    
    func searchArtists(query: String) async throws -> [Artist] {
        let items = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "artists")
        ]
        let response: SearchResponse = try await get("/search", queryItems: items)
        return response.artists ?? []
    }
    
    // MARK: - Discovery
    
    func getNewReleases() async throws -> [Track] {
        try await get("/new-releases", queryItems: nil)
    }
    
    func getRecommendations(seedId: String?) async throws -> [Track] {
        var items: [URLQueryItem]? = nil
        if let seedId = seedId {
            items = [URLQueryItem(name: "seed_id", value: seedId)]
        }
        return try await get("/recommendations", queryItems: items)
    }
    
    // MARK: - Artist
    
    func getArtist(id: String) async throws -> Artist {
        try await get("/artist/\(id)", queryItems: nil)
    }
    
    func getArtistAlbums(id: String) async throws -> [Album] {
        try await get("/artist/\(id)/albums", queryItems: nil)
    }
    
    func getArtistTopTracks(id: String) async throws -> [Track] {
        try await get("/artist/\(id)/top-tracks", queryItems: nil)
    }
    
    // MARK: - Album
    
    func getAlbum(id: String) async throws -> Album {
        try await get("/album/\(id)", queryItems: nil)
    }
    
    // MARK: - Stream
    
    func getStreamUrl(trackId: String) async throws -> String {
        let response: StreamResponse = try await get("/stream/\(trackId)", queryItems: nil)
        return response.streamUrl
    }
    
    // MARK: - Lyrics
    
    func getLyrics(title: String, artist: String, duration: Int) async throws -> Lyrics {
        let items = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "artist", value: artist),
            URLQueryItem(name: "duration", value: String(duration))
        ]
        return try await get("/lyrics", queryItems: items)
    }
    
    // MARK: - Wave
    
    func getWaveNext(history: [String], likedArtistIds: [String], seedTrackIds: [String], count: Int) async throws -> [Track] {
        let body = WaveRequest(
            history: history,
            likedArtistIds: likedArtistIds,
            seedTrackIds: seedTrackIds,
            count: count
        )
        return try await post("/wave/next", body: body)
    }
    
    // MARK: - Private Helpers
    
    private func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]?) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return try await execute(request)
    }
    
    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        return try await execute(request)
    }
    
    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Response Models

private struct SearchResponse: Decodable {
    let tracks: [Track]?
    let artists: [Artist]?
}

private struct StreamResponse: Decodable {
    let streamUrl: String
}

private struct WaveRequest: Encodable {
    let history: [String]
    let likedArtistIds: [String]
    let seedTrackIds: [String]
    let count: Int
}
