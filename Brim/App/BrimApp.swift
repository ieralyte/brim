import SwiftUI

/// Entry point. Brim lives in the menu bar (no Dock icon, set by `LSUIElement`)
/// and draws its island in a panel owned by `NotchWindowController`.
@main
struct BrimApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Brim", systemImage: "rectangle.topthird.inset.filled") {
            MenuContent()
        }

        Settings {
            SettingsView(nowPlaying: appDelegate.nowPlaying, battery: appDelegate.battery,
                         lockScreen: appDelegate.lockScreen, lyrics: appDelegate.lyrics,
                         launchAtLogin: appDelegate.launchAtLogin)
        }
    }
}

/// Items in the menu bar dropdown.
private struct MenuContent: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings…") {
            // Accessory apps are never frontmost, so bring Brim forward
            // before opening the window or it appears behind other apps.
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit Brim") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
