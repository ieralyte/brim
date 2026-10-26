import SwiftUI

/// Settings window. Each milestone adds its own section here.
struct SettingsView: View {
    let nowPlaying: NowPlayingService

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var nowPlayingStatus: String {
        switch nowPlaying.status {
        case .starting: "Starting…"
        case .running: "Working"
        case .unavailable: "Unavailable on this macOS version"
        }
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Version", value: version)
            }
            Section("Diagnostics") {
                LabeledContent("Now Playing", value: nowPlayingStatus)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 220)
    }
}
