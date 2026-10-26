import AppKit
import SwiftUI

/// Owns the notch panel: places it over the notch, watches the mouse,
/// and opens or closes the island on hover.
final class NotchWindowController: NSObject {
    private var panel: NotchPanel?
    private var model: NotchViewModel?
    private var screen: NSScreen?
    private var monitors: [Any] = []
    private var closeTask: Task<Void, Never>?

    /// Room around the open island so its shadow is not clipped.
    private let shadowPadding: CGFloat = 32
    /// How long the pointer must stay away before the island closes.
    private let closeDelay: Duration = .milliseconds(60)

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
            model = NotchViewModel(closedSize: closedSize)
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
            let hosting = NSHostingView(rootView: NotchView(model: model))
            hosting.sizingOptions = []
            panel.contentView = hosting
            self.panel = panel
        }

        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    // MARK: - Hover

    private func installMouseMonitors() {
        // Global: pointer moves while another app is frontmost (almost always).
        if let global = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved, handler: { [weak self] _ in
            self?.pointerMoved()
        }) {
            monitors.append(global)
        }
        // Local: pointer moves delivered to Brim itself, e.g. while Settings is open.
        if let local = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: { [weak self] event in
            self?.pointerMoved()
            return event
        }) {
            monitors.append(local)
        }
    }

    private func pointerMoved() {
        guard let model, let screen else { return }
        let point = NSEvent.mouseLocation

        if model.isOpen {
            if islandRect(for: model, on: screen).insetBy(dx: -8, dy: -8).contains(point) {
                cancelClose()
            } else {
                scheduleClose()
            }
        } else if hoverZone(for: model, on: screen).contains(point) {
            open()
        }
    }

    /// Where the pointer opens the island: the notch, widened a little so it is easy to hit.
    private func hoverZone(for model: NotchViewModel, on screen: NSScreen) -> NSRect {
        let size = model.closedSize
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
