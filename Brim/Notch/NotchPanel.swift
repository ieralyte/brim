import AppKit

/// A borderless, transparent panel that floats above the menu bar on every Space,
/// including full-screen apps, without ever activating Brim.
final class NotchPanel: NSPanel {
    static func make(frame: NSRect) -> NotchPanel {
        let panel = NotchPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        // Closed, the island is just the notch: let every click fall through.
        panel.ignoresMouseEvents = true
        return panel
    }

    // Lets buttons in the expanded island take clicks; `.nonactivatingPanel`
    // keeps the frontmost app active while this happens.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
