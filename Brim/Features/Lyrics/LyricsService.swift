import Foundation
import Observation

/// Finds lyrics for the current song and keeps track of the line being sung.
///
/// Off by default: when on, it sends the song's title, artist, album and length to LRCLIB.
/// It never polls: a timer is set for the moment the next line starts, and reset
/// whenever playback changes (pause, seek, skip).
@Observable
final class LyricsService {
    enum State: Equatable {
        case off
        case waiting
        case loading
        case synced
        case unsynced
        case instrumental
        case notFound
        case failed
    }

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            refresh()
        }
    }

    /// How many seconds early to show each line. Players report their position a beat late
    /// and the eye needs a moment to read, so on-time looks late. Adjustable in Settings.
    var lead: TimeInterval {
        didSet {
            UserDefaults.standard.set(lead, forKey: Self.leadKey)
            updateCurrentLine()
        }
    }
    static let leadRange: ClosedRange<TimeInterval> = -1...3
    static let defaultLead: TimeInterval = 1.0

    private(set) var state: State = .off
    private(set) var lines: [LyricLine] = []
    /// Lyrics without timings, for songs LRCLIB only has plain text for.
    private(set) var plainLines: [String] = []
    private(set) var currentIndex: Int? = nil

    /// The line being sung now, or nil between lines and in instrumental gaps.
    var currentLine: String? {
        guard let currentIndex else { return nil }
        let text = lines[currentIndex].text
        return text.isEmpty ? nil : text
    }

    /// The next line with words in it, for a preview.
    var nextLine: String? {
        let start = (currentIndex ?? -1) + 1
        guard start < lines.count else { return nil }
        return lines[start...].first { !$0.text.isEmpty }?.text
    }

    private static let enabledKey = "lyrics.enabled"
    private static let leadKey = "lyrics.lead"

    @ObservationIgnored private let nowPlaying: NowPlayingService
    @ObservationIgnored private let client = LRCLIBClient()
    @ObservationIgnored private var trackKey: String?
    @ObservationIgnored private var fetchTask: Task<Void, Never>?
    @ObservationIgnored private var lineTimer: Task<Void, Never>?
    @ObservationIgnored private var cache: [String: LyricsResult] = [:]

    init(nowPlaying: NowPlayingService) {
        self.nowPlaying = nowPlaying
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        let savedLead = UserDefaults.standard.object(forKey: Self.leadKey) as? Double
        self.lead = savedLead.map { min(max($0, Self.leadRange.lowerBound), Self.leadRange.upperBound) }
            ?? Self.defaultLead
    }

    func start() {
        observePlayback()
    }

    // MARK: - Following playback

    private func observePlayback() {
        refresh()
        withObservationTracking {
            _ = nowPlaying.info
        } onChange: { [weak self] in
            let service = self
            Task { @MainActor in service?.observePlayback() }
        }
    }

    /// Called whenever the song, its position or the setting changes.
    private func refresh() {
        guard isEnabled else {
            reset(to: .off)
            return
        }
        guard let info = nowPlaying.info, let artist = info.artist else {
            reset(to: .waiting)
            return
        }

        let key = [info.title, artist, info.album ?? "", String(Int(info.duration.rounded()))]
            .joined(separator: "\u{1F}")
        if key != trackKey {
            trackKey = key
            load(key: key, title: info.title, artist: artist, album: info.album, duration: info.duration)
        }
        updateCurrentLine()
    }

    private func reset(to newState: State) {
        fetchTask?.cancel()
        lineTimer?.cancel()
        trackKey = nil
        lines = []
        plainLines = []
        currentIndex = nil
        state = newState
    }

    // MARK: - Fetching

    private func load(key: String, title: String, artist: String, album: String?, duration: TimeInterval) {
        fetchTask?.cancel()
        lines = []
        plainLines = []
        currentIndex = nil

        if let cached = cache[key] {
            apply(cached)
            return
        }

        state = .loading
        fetchTask = Task { [client, weak self] in
            let result: LyricsResult?
            do {
                result = try await client.lyrics(title: title, artist: artist, album: album, duration: duration)
            } catch {
                result = nil
            }
            guard !Task.isCancelled, let self, self.trackKey == key else { return }
            if let result {
                if self.cache.count > 100 { self.cache.removeAll() }
                self.cache[key] = result
                self.apply(result)
            } else {
                self.state = .failed // network trouble: try again next time the song comes up
                self.trackKey = nil
            }
        }
    }

    private func apply(_ result: LyricsResult) {
        switch result {
        case .synced(let found):
            lines = found
            state = .synced
            updateCurrentLine()
        case .unsynced(let text):
            plainLines = text
            state = .unsynced
        case .instrumental: state = .instrumental
        case .notFound: state = .notFound
        }
    }

    // MARK: - Current line

    /// Works out the current line, then sleeps until the next one starts.
    private func updateCurrentLine() {
        lineTimer?.cancel()
        guard state == .synced, let info = nowPlaying.info, !lines.isEmpty else {
            currentIndex = nil
            return
        }

        let position = info.elapsed(at: .now) + lead
        let index = lines.lastIndex { $0.time <= position }
        if index != currentIndex { currentIndex = index }

        guard info.isPlaying else { return }
        let nextIndex = (index ?? -1) + 1
        guard nextIndex < lines.count else { return }

        let rate = info.playbackRate > 0 ? info.playbackRate : 1
        let wait = max((lines[nextIndex].time - position) / rate, 0.05)
        lineTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            self?.updateCurrentLine()
        }
    }
}
