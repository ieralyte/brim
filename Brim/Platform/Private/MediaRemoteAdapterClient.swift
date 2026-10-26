import Foundation

/// Reads and controls Now Playing through Apple's private MediaRemote framework.
///
/// Since macOS 15.4, MediaRemote only answers Apple-signed processes. The bundled
/// mediaremote-adapter (BSD-3-Clause, see `Vendor/MediaRemoteAdapter`) works around
/// this by running inside `/usr/bin/perl`, which Apple signs, and printing updates
/// as one JSON object per line. This class runs that process and parses its output.
///
/// This is private-API territory: if a macOS update breaks it, `start()` keeps
/// failing and `NowPlayingService` reports Now Playing as unavailable.
nonisolated final class MediaRemoteAdapterClient: @unchecked Sendable {
    enum Command: Int {
        case play = 0
        case pause = 1
        case togglePlayPause = 2
        case nextTrack = 4
        case previousTrack = 5
    }

    /// Called on a background queue with each new snapshot (`nil` = nothing playing).
    var onUpdate: (@Sendable (NowPlayingInfo?) -> Void)?
    /// Called on a background queue when the stream process exits unexpectedly.
    var onExit: (@Sendable (_ status: Int32) -> Void)?

    private let perlURL = URL(fileURLWithPath: "/usr/bin/perl")
    private let scriptPath: String
    private let frameworkPath: String

    // Everything below is only touched on `queue`.
    private let queue = DispatchQueue(label: "io.github.brim.mediaremote")
    private var process: Process?
    private var buffer = Data()
    private var state: [String: Any] = [:]

    /// Fails when the adapter is missing from the app bundle.
    init?(bundle: Bundle = .main) {
        guard let script = bundle.path(forResource: "mediaremote-adapter", ofType: "pl"),
              let frameworks = bundle.privateFrameworksPath
        else { return nil }
        let framework = (frameworks as NSString).appendingPathComponent("MediaRemoteAdapter.framework")
        guard FileManager.default.fileExists(atPath: framework),
              FileManager.default.isExecutableFile(atPath: perlURL.path)
        else { return nil }
        scriptPath = script
        frameworkPath = framework
    }

    /// Starts streaming updates. Does nothing if already running.
    func start() {
        queue.async { [self] in
            guard process == nil else { return }
            buffer.removeAll()
            state.removeAll()

            let process = Process()
            process.executableURL = perlURL
            // --micros: precise times. --debounce: merge bursts of updates (e.g. on skip).
            process.arguments = [scriptPath, frameworkPath, "stream", "--micros", "--debounce=100"]
            process.standardError = FileHandle.nullDevice

            let output = Pipe()
            process.standardOutput = output
            output.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard !data.isEmpty, let self else { return }
                self.queue.async { self.consume(data) }
            }

            process.terminationHandler = { [weak self] finished in
                guard let self else { return }
                self.queue.async {
                    output.fileHandleForReading.readabilityHandler = nil
                    guard self.process === finished else { return } // stopped on purpose
                    self.process = nil
                    self.onExit?(finished.terminationStatus)
                }
            }

            do {
                try process.run()
                self.process = process
            } catch {
                onExit?(-1)
            }
        }
    }

    func stop() {
        queue.async { [self] in
            let running = process
            process = nil
            running?.terminate()
        }
    }

    func send(_ command: Command) {
        runOnce(["send", String(command.rawValue)])
    }

    func seek(to seconds: TimeInterval) {
        runOnce(["seek", String(Int(max(seconds, 0) * 1_000_000))])
    }

    // MARK: - Private

    /// Runs a short-lived adapter command without waiting for it.
    private func runOnce(_ arguments: [String]) {
        queue.async { [self] in
            let process = Process()
            process.executableURL = perlURL
            process.arguments = [scriptPath, frameworkPath] + arguments
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
        }
    }

    /// Splits incoming bytes into lines and handles each complete one.
    private func consume(_ data: Data) {
        buffer.append(data)
        while let newline = buffer.firstIndex(of: 0x0A) {
            let line = Data(buffer[buffer.startIndex..<newline])
            buffer.removeSubrange(buffer.startIndex...newline)
            if !line.isEmpty { handle(line) }
        }
    }

    /// Each line is `{"type":"data","diff":Bool,"payload":{...}}`. A diff payload is
    /// merged into the previous state, where a null value means the key was removed.
    private func handle(_ line: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
              let payload = object["payload"] as? [String: Any]
        else { return }

        if (object["diff"] as? NSNumber)?.boolValue == true {
            for (key, value) in payload {
                if value is NSNull {
                    state.removeValue(forKey: key)
                } else {
                    state[key] = value
                }
            }
        } else {
            state = payload
        }

        onUpdate?(NowPlayingInfo(payload: state))
    }
}
