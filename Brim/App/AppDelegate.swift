import AppKit

/// Owns Brim's long-lived services and starts them once AppKit is ready.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let nowPlaying = NowPlayingService()
    let tray = FileTrayService()
    let battery = BatteryService()
    let launchAtLogin = LaunchAtLogin()
    private(set) lazy var lyrics = LyricsService(nowPlaying: nowPlaying)
    private(set) lazy var lockScreen = LockScreenController(nowPlaying: nowPlaying, battery: battery, lyrics: lyrics)
    private lazy var notchController = NotchWindowController(nowPlaying: nowPlaying, tray: tray, battery: battery, lyrics: lyrics)

    func applicationDidFinishLaunching(_ notification: Notification) {
        nowPlaying.start()
        lyrics.start()
        notchController.start() // creates the island, which listens for battery alerts
        battery.start()
        lockScreen.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlaying.stop()
    }
}
