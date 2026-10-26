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

    /// The user's setting. Off hides the lock screen card straight away.
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if !isEnabled { hide() }
        }
    }

    var status: Status {
        if skyLight == nil { return .unavailable }
        return isEnabled ? .ready : .off
    }

    private static let enabledKey = "lockScreen.enabled"
    /// Size of the window holding the card. Transparent areas pass clicks through.
    private static let windowSize = CGSize(width: 440, height: 150)

    @ObservationIgnored private let nowPlaying: NowPlayingService
    @ObservationIgnored private let battery: BatteryService
    @ObservationIgnored private let skyLight: SkyLightSpace?
    @ObservationIgnored private var window: NSWindow?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init(nowPlaying: NowPlayingService, battery: BatteryService) {
        self.nowPlaying = nowPlaying
        self.battery = battery
        self.skyLight = SkyLightSpace()
        self.isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    func start() {
        let distributed = DistributedNotificationCenter.default()
        observers.append(distributed.addObserver(forName: .init("com.apple.screenIsLocked"),
                                                 object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.show() }
        })
        observers.append(distributed.addObserver(forName: .init("com.apple.screenIsUnlocked"),
                                                 object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.hide() }
        })
        // Belt and braces: never leave the card on the desktop after logging back in.
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.hide() }
        })
    }

    // MARK: - Private

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
