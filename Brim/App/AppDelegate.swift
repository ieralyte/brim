import AppKit

/// Owns Brim's long-lived services and starts them once AppKit is ready.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let nowPlaying = NowPlayingService()
    private lazy var notchController = NotchWindowController(nowPlaying: nowPlaying)

    func applicationDidFinishLaunching(_ notification: Notification) {
        nowPlaying.start()
        notchController.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlaying.stop()
    }
}
