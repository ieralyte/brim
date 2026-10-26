import Foundation

/// A snapshot of what is playing, as reported by macOS.
nonisolated struct NowPlayingInfo: Equatable, Sendable {
    var title: String
    var artist: String?
    var album: String?
    var bundleIdentifier: String?
    var isPlaying: Bool
    /// Track length in seconds, or 0 when unknown (for example a live stream).
    var duration: TimeInterval
    /// Playback position in seconds at `timestamp`.
    var elapsed: TimeInterval
    var timestamp: Date
    var playbackRate: Double
    var artworkData: Data?

    /// The playback position at `date`, extrapolated from the last report.
    func elapsed(at date: Date) -> TimeInterval {
        guard isPlaying else { return elapsed }
        let rate = playbackRate > 0 ? playbackRate : 1
        let position = elapsed + date.timeIntervalSince(timestamp) * rate
        return duration > 0 ? min(max(position, 0), duration) : max(position, 0)
    }
}

extension NowPlayingInfo {
    /// Builds a snapshot from a mediaremote-adapter payload (`--micros` key names).
    /// Returns `nil` when nothing is playing.
    nonisolated init?(payload: [String: Any]) {
        guard let title = payload["title"] as? String, !title.isEmpty else { return nil }

        func number(_ key: String) -> Double? {
            (payload[key] as? NSNumber)?.doubleValue
        }

        self.title = title
        artist = (payload["artist"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        album = (payload["album"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        bundleIdentifier = payload["bundleIdentifier"] as? String
        isPlaying = (payload["playing"] as? NSNumber)?.boolValue ?? false
        duration = (number("durationMicros") ?? 0) / 1_000_000
        elapsed = (number("elapsedTimeMicros") ?? 0) / 1_000_000
        timestamp = number("timestampEpochMicros")
            .map { Date(timeIntervalSince1970: $0 / 1_000_000) } ?? Date()
        playbackRate = number("playbackRate") ?? (isPlaying ? 1 : 0)
        artworkData = (payload["artworkData"] as? String).flatMap { Data(base64Encoded: $0) }
    }
}
