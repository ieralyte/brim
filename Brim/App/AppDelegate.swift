import AppKit

/// Owns Brim's long-lived services and starts them once AppKit is ready.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let nowPlaying = NowPlayingService()
    let tray = FileTrayService()
    let battery = BatteryService()
    private lazy var notchController = NotchWindowController(nowPlaying: nowPlaying, tray: tray, battery: battery)

    func applicationDidFinishLaunching(_ notification: Notification) {
        nowPlaying.start()
        notchController.start() // creates the island, which listens for battery alerts
        battery.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlaying.stop()
    }
}
