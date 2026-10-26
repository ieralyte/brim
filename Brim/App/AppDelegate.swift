import AppKit

/// Owns Brim's long-lived services and starts them once AppKit is ready.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let nowPlaying = NowPlayingService()
    let tray = FileTrayService()
    let battery = BatteryService()
    private(set) lazy var lockScreen = LockScreenController(nowPlaying: nowPlaying, battery: battery)
    private lazy var notchController = NotchWindowController(nowPlaying: nowPlaying, tray: tray, battery: battery)

    func applicationDidFinishLaunching(_ notification: Notification) {
        nowPlaying.start()
        notchController.start() // creates the island, which listens for battery alerts
        battery.start()
        lockScreen.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlaying.stop()
    }
}
