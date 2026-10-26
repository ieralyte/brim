import AppKit
import SwiftUI

/// Owns the notch panel: places it over the notch, watches the mouse,
/// and opens or closes the island on hover or when a file is dragged to it.
final class NotchWindowController: NSObject {
    private let nowPlaying: NowPlayingService
    private let tray: FileTrayService
    private let battery: BatteryService
    private var panel: NotchPanel?
    private var model: NotchViewModel?
    private var screen: NSScreen?
    private var monitors: [Any] = []
    private var closeTask: Task<Void, Never>?
    /// The drag pasteboard's change count when the mouse last went down, so a
    /// leftover pasteboard from an earlier drag is not mistaken for a new one.
    private var dragChangeCount = NSPasteboard(name: .drag).changeCount

    /// Room around the open island so its shadow is not clipped.
    private let shadowPadding: CGFloat = 32
    /// How long the pointer must stay away before the island closes.
    private let closeDelay: Duration = .milliseconds(60)

    init(nowPlaying: NowPlayingService, tray: FileTrayService, battery: BatteryService) {
        self.nowPlaying = nowPlaying
        self.tray = tray
        self.battery = battery
        super.init()
    }

    func start() {
        layoutPanel()
        installMouseMonitors()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // MARK: - Layout

    @objc private func screensDidChange(_ notification: Notification) {
        layoutPanel()
    }

    /// Picks the notched screen (or the main screen as a fallback) and pins the panel to its top centre.
    private func layoutPanel() {
        guard let target = NSScreen.withNotch ?? NSScreen.main else { return }
        screen = target

        let closedSize = target.notchSize
            ?? CGSize(width: 180, height: max(target.menuBarHeight, 24))

        let model: NotchViewModel
        if let existing = self.model {
            existing.closedSize = closedSize
            model = existing
        } else {
            model = NotchViewModel(closedSize: closedSize, nowPlaying: nowPlaying, tray: tray, battery: battery)
            self.model = model
        }

        let size = CGSize(width: model.openSize.width + shadowPadding * 2,
                          height: model.openSize.height + shadowPadding)
        let frame = NSRect(x: target.frame.midX - size.width / 2,
                           y: target.frame.maxY - size.height,
                           width: size.width,
                           height: size.height)

        let panel: NotchPanel
        if let existing = self.panel {
            panel = existing
        } else {
            panel = NotchPanel.make(frame: frame)
            let hosting = FirstMouseHostingView(rootView: NotchView(model: model))
            hosting.sizingOptions = []
            panel.contentView = hosting
            self.panel = panel
        }

        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    // MARK: - Hover and drag

    private func installMouseMonitors() {
        let events: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .leftMouseDragged, .leftMouseUp]
        // Global: events going to other apps (almost always).
        if let global = NSEvent.addGlobalMonitorForEvents(matching: events, handler: { [weak self] event in
            self?.handle(event)
        }) {
            monitors.append(global)
        }
        // Local: events going to Brim itself, e.g. dragging a file out of the tray.
        if let local = NSEvent.addLocalMonitorForEvents(matching: events, handler: { [weak self] event in
            self?.handle(event)
            return event
        }) {
            monitors.append(local)
        }
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            dragChangeCount = NSPasteboard(name: .drag).changeCount
        case .leftMouseDragged:
            pointerDragged()
        default:
            pointerMoved()
        }
    }

    private func pointerMoved() {
        guard let model, let screen else { return }
        let point = NSEvent.mouseLocation

        if model.isOpen {
            if islandRect(for: model, on: screen).insetBy(dx: -8, dy: -8).contains(point) {
                cancelClose()
            } else if NSEvent.pressedMouseButtons & 1 == 0 {
                // Stay open while the button is held: a file may be on its way out of the tray.
                scheduleClose()
            }
        } else if hoverZone(for: model, on: screen).contains(point) {
            open()
        }
    }

    /// Opens the island when a file drag reaches the notch, so it can be dropped in the tray.
    private func pointerDragged() {
        guard let model, let screen else { return }
        if model.isOpen {
            cancelClose()
        } else if isDraggingFiles,
                  hoverZone(for: model, on: screen).insetBy(dx: -24, dy: -12).contains(NSEvent.mouseLocation) {
            open()
        }
    }

    private var isDraggingFiles: Bool {
        let pasteboard = NSPasteboard(name: .drag)
        return pasteboard.changeCount != dragChangeCount
            && pasteboard.types?.contains(.fileURL) == true
    }

    /// Where the pointer opens the island: the closed island (wings included), widened a little so it is easy to hit.
    private func hoverZone(for model: NotchViewModel, on screen: NSScreen) -> NSRect {
        let size = model.closedDisplaySize
        return NSRect(x: screen.frame.midX - size.width / 2 - 12,
                      y: screen.frame.maxY - size.height - 4,
                      width: size.width + 24,
                      height: size.height + 8)
    }

    /// The open island in screen coordinates, ears included.
    private func islandRect(for model: NotchViewModel, on screen: NSScreen) -> NSRect {
        let size = model.openSize
        let ear = model.earRadius
        return NSRect(x: screen.frame.midX - size.width / 2 - ear,
                      y: screen.frame.maxY - size.height,
                      width: size.width + ear * 2,
                      height: size.height)
    }

    private func open() {
        cancelClose()
        panel?.ignoresMouseEvents = false
        model?.open()
    }

    private func close() {
        closeTask = nil
        panel?.ignoresMouseEvents = true
        model?.close()
    }

    private func scheduleClose() {
        guard closeTask == nil else { return }
        closeTask = Task { [weak self, closeDelay] in
            try? await Task.sleep(for: closeDelay)
            guard !Task.isCancelled else { return }
            self?.close()
        }
    }

    private func cancelClose() {
        closeTask?.cancel()
        closeTask = nil
    }
}
