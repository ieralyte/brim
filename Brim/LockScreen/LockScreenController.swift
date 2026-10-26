import AppKit
import Observation
import SwiftUI

/// Shows Now Playing and battery on the lock screen, and removes them the moment the Mac unlocks.
@Observable
final class LockScreenController {
    enum Status {
        case ready
        case off
        case unavailable
    }

    /// When to keep the display on while the Mac is locked. macOS otherwise turns
    /// the lock screen off after about 30 seconds, whatever the Energy settings say.
    enum KeepAwake: String, CaseIterable, Identifiable {
        case never
        case whilePlaying
        case always

        var id: String { rawValue }

        var label: String {
            switch self {
            case .never: "Never"
            case .whilePlaying: "While music is playing"
            case .always: "Always"
            }
        }
    }

    /// The user's setting. Off hides the lock screen card straight away.
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if !isEnabled { hide() }
        }
    }

    var keepAwake: KeepAwake {
        didSet {
            UserDefaults.standard.set(keepAwake.rawValue, forKey: Self.keepAwakeKey)
            updateDisplayWake()
        }
    }

    /// Only keep the display on while connected to power, to save battery.
    var keepAwakeOnlyWhenPluggedIn: Bool {
        didSet {
            UserDefaults.standard.set(keepAwakeOnlyWhenPluggedIn, forKey: Self.pluggedInKey)
            updateDisplayWake()
        }
    }

    var status: Status {
        if skyLight == nil { return .unavailable }
        return isEnabled ? .ready : .off
    }

    private static let enabledKey = "lockScreen.enabled"
    private static let keepAwakeKey = "lockScreen.keepAwake"
    private static let pluggedInKey = "lockScreen.keepAwakeOnlyWhenPluggedIn"
    /// Size of the window holding the card. Transparent areas pass clicks through.
    private static let windowSize = CGSize(width: 440, height: 190)

    @ObservationIgnored private let nowPlaying: NowPlayingService
    @ObservationIgnored private let battery: BatteryService
    @ObservationIgnored private let skyLight: SkyLightSpace?
    @ObservationIgnored private var window: NSWindow?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private let displayWake = DisplayWakeAssertion()
    @ObservationIgnored private var isLocked = false

    init(nowPlaying: NowPlayingService, battery: BatteryService) {
        self.nowPlaying = nowPlaying
        self.battery = battery
        self.skyLight = SkyLightSpace()
        let defaults = UserDefaults.standard
        self.isEnabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
        self.keepAwake = defaults.string(forKey: Self.keepAwakeKey).flatMap { KeepAwake(rawValue: $0) } ?? .whilePlaying
        self.keepAwakeOnlyWhenPluggedIn = defaults.object(forKey: Self.pluggedInKey) as? Bool ?? false
    }

    func start() {
        let distributed = DistributedNotificationCenter.default()
        observers.append(distributed.addObserver(forName: .init("com.apple.screenIsLocked"),
                                                 object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.locked() }
        })
        observers.append(distributed.addObserver(forName: .init("com.apple.screenIsUnlocked"),
                                                 object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.unlocked() }
        })
        // Belt and braces: never leave the card on the desktop after logging back in.
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.unlocked() }
        })
    }

    // MARK: - Lock state

    private func locked() {
        isLocked = true
        show()
        updateDisplayWake()
    }

    private func unlocked() {
        isLocked = false
        hide()
        updateDisplayWake()
    }

    // MARK: - Keeping the display on

    /// Holds or releases the display assertion, then watches playback and power
    /// for as long as the Mac stays locked, so it reacts when either changes.
    private func updateDisplayWake() {
        guard isLocked else {
            displayWake.release()
            return
        }

        let pluggedIn = battery.snapshot?.isPluggedIn ?? true // no battery: a desktop Mac
        let wanted: Bool
        switch keepAwake {
        case .never: wanted = false
        case .whilePlaying: wanted = nowPlaying.isPlaying
        case .always: wanted = true
        }

        if wanted && (pluggedIn || !keepAwakeOnlyWhenPluggedIn) {
            displayWake.hold(reason: "Brim is showing Now Playing on the lock screen")
        } else {
            displayWake.release()
        }

        withObservationTracking {
            _ = nowPlaying.isPlaying
            _ = battery.snapshot
        } onChange: { [weak self] in
            let controller = self
            Task { @MainActor in controller?.updateDisplayWake() }
        }
    }

    // MARK: - Card

    private func show() {
        guard isEnabled, let skyLight, let screen = NSScreen.withNotch ?? NSScreen.main else { return }
        let window = self.window ?? makeWindow()
        self.window = window

        // Centred, just below the lock screen clock.
        let size = Self.windowSize
        window.setFrame(NSRect(x: screen.frame.midX - size.width / 2,
                               y: screen.frame.maxY - screen.frame.height * 0.36 - size.height,
                               width: size.width, height: size.height),
                        display: false)

        window.alphaValue = 0
        window.orderFrontRegardless()
        guard skyLight.add(window) else {
            window.orderOut(nil)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            window.animator().alphaValue = 1
        }
    }

    private func hide() {
        window?.orderOut(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = LockScreenWindow(contentRect: NSRect(origin: .zero, size: Self.windowSize),
                                      styleMask: [.borderless, .fullSizeContentView],
                                      backing: .buffered, defer: false)
        let hosting = FirstMouseHostingView(rootView: LockScreenView(nowPlaying: nowPlaying, battery: battery))
        hosting.sizingOptions = []
        window.contentView = hosting
        return window
    }
}

/// A transparent borderless window that macOS allows to appear before anyone logs in.
private final class LockScreenWindow: NSWindow {
    override init(contentRect: NSRect, styleMask: NSWindow.StyleMask,
                  backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: styleMask, backing: backing, defer: flag)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        isReleasedWhenClosed = false
        canBecomeVisibleWithoutLogin = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        level = NSWindow.Level(rawValue: Int(Int32.max - 2))
    }

    override var canBecomeKey: Bool { true }
}
