import AppKit

/// Starts the long-lived parts of Brim once AppKit is ready.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let notchController = NotchWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        notchController.start()
    }
}
