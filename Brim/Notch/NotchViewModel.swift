import SwiftUI

/// The island's state. Views read it; `NotchWindowController` changes it.
@Observable
final class NotchViewModel {
    enum State {
        case closed
        case open
    }

    /// What the closed island is showing beside the notch, if anything.
    enum LiveActivity: Equatable {
        case battery(BatteryAlert)
        case nowPlaying
    }

    private(set) var state: State = .closed

    /// Size of the hardware notch, or of the fallback pill on screens without one.
    var closedSize: CGSize

    /// False on displays without a notch (external monitors, a closed MacBook lid).
    /// There the island stays hidden while idle instead of drawing a fake notch.
    var hasHardwareNotch = true

    /// Size of the expanded island.
    let openSize = CGSize(width: 600, height: 190)

    let nowPlaying: NowPlayingService
    let tray: FileTrayService
    let battery: BatteryService

    /// A charging or low-battery notice, shown for a few seconds.
    private(set) var batteryAlert: BatteryAlert?
    @ObservationIgnored private var alertTask: Task<Void, Never>?

    init(closedSize: CGSize, nowPlaying: NowPlayingService, tray: FileTrayService, battery: BatteryService) {
        self.closedSize = closedSize
        self.nowPlaying = nowPlaying
        self.tray = tray
        self.battery = battery
        battery.onAlert = { [weak self] alert in self?.show(alert) }
    }

    var isOpen: Bool { state == .open }

    /// Battery notices take priority over Now Playing.
    var liveActivity: LiveActivity? {
        if let batteryAlert { return .battery(batteryAlert) }
        return nowPlaying.isPlaying ? .nowPlaying : nil
    }

    /// Whether the island is drawn at all. On a real notch it always is (it covers the notch);
    /// elsewhere only when open, or while something is live beside it.
    var isIslandVisible: Bool {
        isOpen || hasHardwareNotch || liveActivity != nil
    }

    var wingWidth: CGFloat { closedSize.height + 12 }

    /// The closed island, including the wings either side of the notch when an activity is showing.
    var closedDisplaySize: CGSize {
        liveActivity == nil
            ? closedSize
            : CGSize(width: closedSize.width + wingWidth * 2, height: closedSize.height)
    }

    var currentSize: CGSize { isOpen ? openSize : closedDisplaySize }

    /// Corner radius of the outward "ears" where the island meets the top of the screen.
    var earRadius: CGFloat {
        guard hasHardwareNotch else { return 0 } // a floating pill has no ears
        return isOpen ? 14 : 6
    }

    /// Gap between the top of the screen and a floating pill, on displays without a notch.
    var floatInset: CGFloat { hasHardwareNotch ? 0 : 3 }

    /// Corner radius of the island's bottom corners.
    var bottomRadius: CGFloat { isOpen ? 28 : 12 }

    func open() {
        guard state != .open else { return }
        dismissAlert() // opening the island counts as seeing the notice
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            state = .open
        }
    }

    func close() {
        guard state != .closed else { return }
        withAnimation(.spring(response: 0.2, dampingFraction: 1.0)) {
            state = .closed
        }
    }

    private func show(_ alert: BatteryAlert) {
        alertTask?.cancel()
        batteryAlert = alert
        let duration: Duration = alert.kind == .charging ? .seconds(3) : .seconds(6)
        alertTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.dismissAlert()
        }
    }

    private func dismissAlert() {
        alertTask?.cancel()
        alertTask = nil
        batteryAlert = nil
    }
}
