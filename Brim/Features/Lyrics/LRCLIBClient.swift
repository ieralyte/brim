import Foundation

/// Looks up lyrics on LRCLIB (https://lrclib.net), a free community database with no API key.
/// Sends only the song's title, artist, album and length.
nonisolated struct LRCLIBClient: Sendable {
    private struct Record: Decodable {
        let duration: Double?
        let instrumental: Bool?
        let plainLyrics: String?
        let syncedLyrics: String?
    }

    enum Failure: Error {
        case badResponse(Int)
    }

    private let base = URL(string: "https://lrclib.net/api")!
    private let session: URLSession
    private let userAgent: String

    init(session: URLSession = .shared) {
        self.session = session
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        // LRCLIB asks clients to identify themselves.
        userAgent = "Brim/\(version) (https://github.com/ieralyte/brim)"
    }

    func lyrics(title: String, artist: String, album: String?, duration: TimeInterval) async throws -> LyricsResult {
        // 1. Exact lookup: LRCLIB matches the length within ±2 seconds.
        var items = [URLQueryItem(name: "track_name", value: title),
                     URLQueryItem(name: "artist_name", value: artist)]
        if let album, !album.isEmpty { items.append(URLQueryItem(name: "album_name", value: album)) }
        if duration >= 1 { items.append(URLQueryItem(name: "duration", value: String(Int(duration.rounded())))) }

        if let record: Record = try await get("get", items) {
            return Self.result(from: record)
        }

        // 2. Fall back to search (title and artist only), preferring timed lyrics of a similar length.
        let candidates: [Record] = try await get("search", [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist),
        ]) ?? []
        let close = candidates.filter { record in
            guard duration >= 1, let length = record.duration else { return true }
            return abs(length - duration) <= 3
        }
        let best = close.first { $0.syncedLyrics?.isEmpty == false } ?? close.first
        return best.map(Self.result(from:)) ?? .notFound
    }

    private static func result(from record: Record) -> LyricsResult {
        if record.instrumental == true { return .instrumental }
        if let synced = record.syncedLyrics, !synced.isEmpty {
            let lines = LRCParser.parse(synced)
            if !lines.isEmpty { return .synced(lines) }
        }
        if let plain = record.plainLyrics, !plain.isEmpty {
            return .unsynced(plain.components(separatedBy: .newlines))
        }
        return .notFound
    }

    /// GETs `path` and decodes it, or returns nil for 404 (not in the database).
    private func get<T: Decodable>(_ path: String, _ items: [URLQueryItem]) async throws -> T? {
        var components = URLComponents(url: base.appending(path: path), resolvingAgainstBaseURL: false)!
        components.queryItems = items
        var request = URLRequest(url: components.url!, timeoutInterval: 10)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 404 { return nil }
        guard (200..<300).contains(status) else { throw Failure.badResponse(status) }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
