import AppKit
import Observation

/// Publishes what is playing and forwards playback commands.
/// Views observe it; it never polls, updates arrive as the player reports them.
@Observable
final class NowPlayingService {
    enum Status {
        case starting
        case running
        case unavailable
    }

    private(set) var info: NowPlayingInfo?
    private(set) var artwork: NSImage?
    private(set) var status: Status = .starting

    var isPlaying: Bool { info?.isPlaying == true }

    @ObservationIgnored private let client: MediaRemoteAdapterClient?
    @ObservationIgnored private var failedStarts = 0
    @ObservationIgnored private var artworkSource: Data?

    /// Give up after this many crashes in a row, so a broken adapter doesn't respawn forever.
    private let maxRestarts = 3

    init() {
        client = MediaRemoteAdapterClient()
        if client == nil { status = .unavailable }
    }

    func start() {
        guard let client else { return }
        // Callbacks arrive on a background queue; hop to the main actor to update state.
        client.onUpdate = { [weak self] info in
            let service = self
            Task { @MainActor in service?.apply(info) }
        }
        client.onExit = { [weak self] code in
            let service = self
            Task { @MainActor in service?.handleExit(code) }
        }
        client.start()
        status = .running
    }

    func stop() {
        client?.stop()
    }

    // MARK: - Commands

    func togglePlayPause() {
        client?.send(.togglePlayPause)
        // Flip the button immediately; the next update from the player confirms it.
        guard var info else { return }
        info.elapsed = info.elapsed(at: .now)
        info.timestamp = .now
        info.isPlaying.toggle()
        self.info = info
    }

    func nextTrack() {
        client?.send(.nextTrack)
    }

    func previousTrack() {
        client?.send(.previousTrack)
    }

    func seek(to seconds: TimeInterval) {
        client?.seek(to: seconds)
        guard var info else { return }
        info.elapsed = seconds
        info.timestamp = .now
        self.info = info
    }

    // MARK: - Updates

    private func apply(_ newInfo: NowPlayingInfo?) {
        failedStarts = 0
        status = .running
        if info != newInfo { info = newInfo }

        let data = newInfo?.artworkData
        if data != artworkSource {
            artworkSource = data
            artwork = data.flatMap(NSImage.init(data:))
        }
    }

    private func handleExit(_ code: Int32) {
        info = nil
        artwork = nil
        artworkSource = nil
        failedStarts += 1
        guard failedStarts <= maxRestarts else {
            status = .unavailable
            return
        }
        let delay = Duration.seconds(2 * failedStarts)
        Task { [weak self] in
            try? await Task.sleep(for: delay)
            self?.client?.start()
        }
    }
}
