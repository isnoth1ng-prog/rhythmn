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
    
    // Default to the user's PC IP address on the local network
    var baseURL: String {
        get {
            UserDefaults.standard.string(forKey: "custom_backend_url") ?? "http://192.168.0.13:8000/api"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "custom_backend_url")
        }
    }
    
    // Fast session for backend attempts so fallback triggers immediately when PC is offline
    private let backendSession: URLSession
    // Reliable session for public Apple / LRCLIB services
    private let publicSession: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let backendConfig = URLSessionConfiguration.default
        backendConfig.timeoutIntervalForRequest = 3.0
        backendConfig.timeoutIntervalForResource = 5.0
        self.backendSession = URLSession(configuration: backendConfig)
        
        let publicConfig = URLSessionConfiguration.default
        publicConfig.timeoutIntervalForRequest = 10.0
        publicConfig.timeoutIntervalForResource = 15.0
        self.publicSession = URLSession(configuration: publicConfig)
        
        self.decoder = JSONDecoder()
    }
    
    // MARK: - Search
    
    func searchTracks(query: String) async throws -> [Track] {
        let items = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "tracks")
        ]
        do {
            let response: SearchResponse = try await get("/search", queryItems: items)
            if let tracks = response.tracks, !tracks.isEmpty {
                return tracks
            }
        } catch {
            print("Backend searchTracks failed, using autonomous iTunes fallback: \(error.localizedDescription)")
        }
        return await fetchiTunesTracks(term: query)
    }
    
    func searchArtists(query: String) async throws -> [Artist] {
        let items = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "artists")
        ]
        do {
            let response: SearchResponse = try await get("/search", queryItems: items)
            if let artists = response.artists, !artists.isEmpty {
                return artists
            }
        } catch {
            print("Backend searchArtists failed, using autonomous iTunes fallback: \(error.localizedDescription)")
        }
        return await fetchiTunesArtists(term: query)
    }
    
    // MARK: - Discovery
    
    func getNewReleases() async throws -> [Track] {
        do {
            let tracks: [Track] = try await get("/new-releases", queryItems: nil)
            if !tracks.isEmpty {
                return tracks
            }
        } catch {
            print("Backend getNewReleases failed, using autonomous iTunes fallback: \(error.localizedDescription)")
        }
        return await fetchiTunesTopCharts(limit: 30)
    }
    
    func getRecommendations(seedId: String?) async throws -> [Track] {
        var items: [URLQueryItem]? = nil
        if let seedId = seedId {
            items = [URLQueryItem(name: "seed_id", value: seedId)]
        }
        do {
            let tracks: [Track] = try await get("/recommendations", queryItems: items)
            if !tracks.isEmpty {
                return tracks
            }
        } catch {
            print("Backend getRecommendations failed, using autonomous iTunes fallback: \(error.localizedDescription)")
        }
        return await fetchiTunesRecommendations()
    }
    
    // MARK: - Artist
    
    func getArtist(id: String) async throws -> Artist {
        do {
            return try await get("/artist/\(id)", queryItems: nil)
        } catch {
            print("Backend getArtist failed, using autonomous iTunes fallback: \(error.localizedDescription)")
            return await fetchiTunesArtist(id: id)
        }
    }
    
    func getArtistAlbums(id: String) async throws -> [Album] {
        do {
            let albums: [Album] = try await get("/artist/\(id)/albums", queryItems: nil)
            if !albums.isEmpty {
                return albums
            }
        } catch {
            print("Backend getArtistAlbums failed, using autonomous iTunes fallback: \(error.localizedDescription)")
        }
        return await fetchiTunesArtistAlbums(artistId: id)
    }
    
    func getArtistTopTracks(id: String) async throws -> [Track] {
        do {
            let tracks: [Track] = try await get("/artist/\(id)/top-tracks", queryItems: nil)
            if !tracks.isEmpty {
                return tracks
            }
        } catch {
            print("Backend getArtistTopTracks failed, using autonomous iTunes fallback: \(error.localizedDescription)")
        }
        return await fetchiTunesArtistTopTracks(artistId: id)
    }
    
    // MARK: - Album
    
    func getAlbum(id: String) async throws -> Album {
        do {
            return try await get("/album/\(id)", queryItems: nil)
        } catch {
            print("Backend getAlbum failed, using autonomous iTunes fallback: \(error.localizedDescription)")
            return await fetchiTunesAlbum(albumId: id)
        }
    }
    
    // MARK: - Stream
    
    func getStreamUrl(trackId: String, title: String? = nil, artist: String? = nil) async throws -> String {
        // Direct stream URL already passed
        if trackId.hasPrefix("http://") || trackId.hasPrefix("https://") {
            return trackId
        }
        
        // 1. Try backend stream endpoint
        do {
            let response: StreamResponse = try await get("/stream/\(trackId)", queryItems: nil)
            if !response.streamUrl.isEmpty {
                return response.streamUrl
            }
        } catch {
            print("Backend getStreamUrl failed: \(error.localizedDescription)")
        }
        
        // 2. Try numeric iTunes track ID lookup
        if Int(trackId) != nil {
            if let stream = await fetchiTunesStreamUrl(trackId: trackId), !stream.isEmpty {
                return stream
            }
        }
        
        // 3. Search iTunes by title & artist for audio stream
        let searchQuery = [title, artist].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        if !searchQuery.isEmpty {
            let results = await fetchiTunesTracks(term: searchQuery, limit: 3)
            if let matched = results.first(where: { $0.streamUrl != nil && !$0.streamUrl!.isEmpty }),
               let stream = matched.streamUrl {
                return stream
            }
            if let first = results.first, let stream = first.streamUrl, !stream.isEmpty {
                return stream
            }
        }
        
        return ""
    }
    
    // MARK: - Lyrics
    
    func getLyrics(title: String, artist: String, duration: Int) async throws -> Lyrics {
        // 1. Autonomous LRCLIB fetch directly from mobile client
        if let lyrics = await fetchDirectLRCLIB(title: title, artist: artist, duration: duration) {
            return lyrics
        }
        
        // 2. Fallback to PC backend lyrics endpoint
        let items = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "artist", value: artist),
            URLQueryItem(name: "duration", value: String(duration))
        ]
        do {
            return try await get("/lyrics", queryItems: items)
        } catch {
            return Lyrics(trackId: "", lines: [], plainText: nil, synced: false)
        }
    }
    
    // MARK: - Wave
    
    func getWaveNext(history: [String], likedArtistIds: [String], seedTrackIds: [String], count: Int) async throws -> [Track] {
        let body = WaveRequest(
            history: history,
            likedArtistIds: likedArtistIds,
            seedTrackIds: seedTrackIds,
            count: count
        )
        do {
            let tracks: [Track] = try await post("/wave/next", body: body)
            if !tracks.isEmpty {
                return tracks
            }
        } catch {
            print("Backend getWaveNext failed, generating autonomous mix: \(error.localizedDescription)")
        }
        
        // Autonomous Wave Generator
        var wave: [Track] = []
        let historySet = Set(history)
        
        // Seed from top charts
        let trending = await fetchiTunesTopCharts(limit: count * 2)
        wave.append(contentsOf: trending.filter { !historySet.contains($0.id) })
        
        // Seed from search keywords for variety
        let genres = ["pop", "rock", "hip hop", "electronic", "indie", "r&b"]
        if let randomGenre = genres.randomElement() {
            let genreTracks = await fetchiTunesTracks(term: randomGenre, limit: count)
            wave.append(contentsOf: genreTracks.filter { !historySet.contains($0.id) })
        }
        
        wave.shuffle()
        return Array(wave.prefix(count))
    }
    
    // MARK: - Private Backend Helpers
    
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
        
        return try await execute(request, on: backendSession)
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
        
        return try await execute(request, on: backendSession)
    }
    
    private func execute<T: Decodable>(_ request: URLRequest, on session: URLSession) async throws -> T {
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
    
    // MARK: - Autonomous Engine (Apple Music / iTunes + LRCLIB)
    
    private func fetchiTunesTracks(term: String, limit: Int = 25) async -> [Track] {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=song&limit=\(limit)") else {
            return []
        }
        
        do {
            let (data, _) = try await publicSession.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                return []
            }
            
            return results.compactMap { dict -> Track? in
                guard let idNum = dict["trackId"] as? Int,
                      let title = dict["trackName"] as? String,
                      let artist = dict["artistName"] as? String else {
                    return nil
                }
                let artistId = (dict["artistId"] as? Int).map(String.init) ?? ""
                let albumTitle = dict["collectionName"] as? String
                let rawArt = (dict["artworkUrl100"] as? String) ?? ""
                let artwork = rawArt.replacingOccurrences(of: "100x100bb", with: "600x600bb")
                let durationMs = (dict["trackTimeMillis"] as? Double) ?? 180000
                let previewUrl = dict["previewUrl"] as? String
                
                return Track(
                    id: String(idNum),
                    title: title,
                    artist: artist,
                    artistId: artistId,
                    albumTitle: albumTitle,
                    thumbnailUrl: artwork,
                    duration: durationMs / 1000.0,
                    streamUrl: previewUrl
                )
            }
        } catch {
            print("fetchiTunesTracks error: \(error.localizedDescription)")
            return []
        }
    }
    
    private func fetchiTunesArtists(term: String, limit: Int = 15) async -> [Artist] {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=musicArtist&limit=\(limit)") else {
            return []
        }
        
        do {
            let (data, _) = try await publicSession.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                return []
            }
            
            return results.compactMap { dict -> Artist? in
                guard let artistId = dict["artistId"] as? Int,
                      let name = dict["artistName"] as? String else {
                    return nil
                }
                let genre = dict["primaryGenreName"] as? String ?? "Артист"
                return Artist(
                    id: String(artistId),
                    name: name,
                    imageUrl: "",
                    subscriberCount: genre,
                    description: nil
                )
            }
        } catch {
            return []
        }
    }
    
    private func fetchiTunesTopCharts(limit: Int = 30) async -> [Track] {
        // Try iTunes RSS top songs feed
        if let rssUrl = URL(string: "https://itunes.apple.com/us/rss/topsongs/limit=\(limit)/json") {
            do {
                let (data, _) = try await publicSession.data(from: rssUrl)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let feed = json["feed"] as? [String: Any],
                   let entries = feed["entry"] as? [[String: Any]] {
                    let tracks: [Track] = entries.compactMap { e in
                        guard let titleDict = e["im:name"] as? [String: Any],
                              let title = titleDict["label"] as? String,
                              let artistDict = e["im:artist"] as? [String: Any],
                              let artist = artistDict["label"] as? String else {
                            return nil
                        }
                        
                        let idDict = e["id"] as? [String: Any]
                        let attr = idDict?["attributes"] as? [String: Any]
                        let trackId = (attr?["im:id"] as? String) ?? UUID().uuidString
                        
                        var artwork = ""
                        if let images = e["im:image"] as? [[String: Any]], let last = images.last,
                           let rawUrl = last["label"] as? String {
                            artwork = rawUrl.replacingOccurrences(of: "170x170bb", with: "600x600bb")
                        }
                        
                        var previewUrl: String? = nil
                        if let links = e["link"] as? [[String: Any]] {
                            for link in links {
                                if let lAttrs = link["attributes"] as? [String: Any],
                                   let type = lAttrs["type"] as? String,
                                   type.contains("audio"),
                                   let href = lAttrs["href"] as? String {
                                    previewUrl = href
                                    break
                                }
                            }
                        }
                        
                        return Track(
                            id: trackId,
                            title: title,
                            artist: artist,
                            artistId: "",
                            albumTitle: nil,
                            thumbnailUrl: artwork,
                            duration: 180,
                            streamUrl: previewUrl
                        )
                    }
                    if !tracks.isEmpty {
                        return tracks
                    }
                }
            } catch {
                print("iTunes RSS feed failed, falling back to top hits search: \(error)")
            }
        }
        
        // Fallback: iTunes top hits search
        return await fetchiTunesTracks(term: "top hits 2024", limit: limit)
    }
    
    private func fetchiTunesRecommendations() async -> [Track] {
        let queries = ["trending hits", "viral pop", "billboard hot 100", "top songs"]
        let query = queries.randomElement() ?? "top songs"
        let tracks = await fetchiTunesTracks(term: query, limit: 25)
        return tracks.shuffled()
    }
    
    private func fetchiTunesArtist(id: String) async -> Artist {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(id)") else {
            return Artist(id: id, name: "Исполнитель", imageUrl: "", subscriberCount: nil, description: nil)
        }
        do {
            let (data, _) = try await publicSession.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let first = results.first,
               let name = first["artistName"] as? String {
                let genre = first["primaryGenreName"] as? String ?? ""
                return Artist(id: id, name: name, imageUrl: "", subscriberCount: genre, description: nil)
            }
        } catch {}
        return Artist(id: id, name: "Исполнитель", imageUrl: "", subscriberCount: nil, description: nil)
    }
    
    private func fetchiTunesArtistTopTracks(artistId: String) async -> [Track] {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(artistId)&entity=song&limit=25") else {
            return []
        }
        do {
            let (data, _) = try await publicSession.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                return []
            }
            return results.compactMap { dict -> Track? in
                guard let wrapper = dict["wrapperType"] as? String, wrapper == "track",
                      let idNum = dict["trackId"] as? Int,
                      let title = dict["trackName"] as? String,
                      let artist = dict["artistName"] as? String else {
                    return nil
                }
                let rawArt = (dict["artworkUrl100"] as? String) ?? ""
                let artwork = rawArt.replacingOccurrences(of: "100x100bb", with: "600x600bb")
                let durationMs = (dict["trackTimeMillis"] as? Double) ?? 180000
                let preview = dict["previewUrl"] as? String
                return Track(
                    id: String(idNum),
                    title: title,
                    artist: artist,
                    artistId: artistId,
                    albumTitle: dict["collectionName"] as? String,
                    thumbnailUrl: artwork,
                    duration: durationMs / 1000.0,
                    streamUrl: preview
                )
            }
        } catch {
            return []
        }
    }
    
    private func fetchiTunesArtistAlbums(artistId: String) async -> [Album] {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(artistId)&entity=album&limit=20") else {
            return []
        }
        do {
            let (data, _) = try await publicSession.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                return []
            }
            return results.compactMap { dict -> Album? in
                guard let wrapper = dict["wrapperType"] as? String, wrapper == "collection",
                      let collId = dict["collectionId"] as? Int,
                      let title = dict["collectionName"] as? String else {
                    return nil
                }
                let rawArt = (dict["artworkUrl100"] as? String) ?? ""
                let artwork = rawArt.replacingOccurrences(of: "100x100bb", with: "600x600bb")
                let yearStr = (dict["releaseDate"] as? String)?.prefix(4).description
                return Album(
                    id: String(collId),
                    title: title,
                    artistName: (dict["artistName"] as? String) ?? "",
                    thumbnailUrl: artwork,
                    year: yearStr,
                    tracks: []
                )
            }
        } catch {
            return []
        }
    }
    
    private func fetchiTunesAlbum(albumId: String) async -> Album {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(albumId)&entity=song") else {
            return Album(id: albumId, title: "Альбом", artistName: "", thumbnailUrl: "", year: nil, tracks: [])
        }
        do {
            let (data, _) = try await publicSession.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                return Album(id: albumId, title: "Альбом", artistName: "", thumbnailUrl: "", year: nil, tracks: [])
            }
            var title = "Альбом"
            var artistName = ""
            var artwork = ""
            var year: String? = nil
            var tracks: [Track] = []
            
            for item in results {
                let wrapper = item["wrapperType"] as? String
                if wrapper == "collection" {
                    title = (item["collectionName"] as? String) ?? title
                    artistName = (item["artistName"] as? String) ?? artistName
                    artwork = ((item["artworkUrl100"] as? String) ?? "").replacingOccurrences(of: "100x100bb", with: "600x600bb")
                    year = (item["releaseDate"] as? String)?.prefix(4).description
                } else if wrapper == "track" {
                    if let trackId = item["trackId"] as? Int,
                       let trackName = item["trackName"] as? String {
                        let durationMs = (item["trackTimeMillis"] as? Double) ?? 180000
                        let preview = item["previewUrl"] as? String
                        tracks.append(Track(
                            id: String(trackId),
                            title: trackName,
                            artist: (item["artistName"] as? String) ?? artistName,
                            artistId: (item["artistId"] as? Int).map(String.init) ?? "",
                            albumTitle: title,
                            thumbnailUrl: artwork,
                            duration: durationMs / 1000.0,
                            streamUrl: preview
                        ))
                    }
                }
            }
            return Album(id: albumId, title: title, artistName: artistName, thumbnailUrl: artwork, year: year, tracks: tracks)
        } catch {
            return Album(id: albumId, title: "Альбом", artistName: "", thumbnailUrl: "", year: nil, tracks: [])
        }
    }
    
    private func fetchiTunesStreamUrl(trackId: String) async -> String? {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(trackId)") else { return nil }
        do {
            let (data, _) = try await publicSession.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first else {
                return nil
            }
            return first["previewUrl"] as? String
        } catch {
            return nil
        }
    }
    
    // MARK: - Direct LRCLIB Client for Real-Time Synced Lyrics
    
    private func fetchDirectLRCLIB(title: String, artist: String, duration: Int) async -> Lyrics? {
        guard let encTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        let urlString = "https://lrclib.net/api/get?track_name=\(encTitle)&artist_name=\(encArtist)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Rhythm-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await publicSession.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let syncedText = json["syncedLyrics"] as? String
                let plainText = json["plainLyrics"] as? String
                
                if let synced = syncedText, !synced.isEmpty {
                    let lines = parseLRC(synced)
                    return Lyrics(trackId: "", lines: lines, plainText: plainText, synced: true)
                } else if let plain = plainText, !plain.isEmpty {
                    return Lyrics(trackId: "", lines: [], plainText: plain, synced: false)
                }
            }
        } catch {
            print("LRCLIB direct fetch error: \(error.localizedDescription)")
        }
        return nil
    }
    
    private func parseLRC(_ lrc: String) -> [LyricsLine] {
        var lines: [LyricsLine] = []
        let rawLines = lrc.components(separatedBy: "\n")
        let regex = try? NSRegularExpression(pattern: "\\[(\\d+):(\\d+(?:\\.\\d+)?)\\](.*)")
        
        for line in rawLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let nsRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
            
            if let match = regex?.firstMatch(in: trimmed, options: [], range: nsRange),
               match.numberOfRanges >= 4 {
                guard let minRange = Range(match.range(at: 1), in: trimmed),
                      let secRange = Range(match.range(at: 2), in: trimmed),
                      let textRange = Range(match.range(at: 3), in: trimmed),
                      let minutes = Double(trimmed[minRange]),
                      let seconds = Double(trimmed[secRange]) else {
                    continue
                }
                let text = String(trimmed[textRange]).trimmingCharacters(in: .whitespaces)
                let timeSec = minutes * 60.0 + seconds
                lines.append(LyricsLine(time: timeSec, text: text))
            }
        }
        return lines
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
