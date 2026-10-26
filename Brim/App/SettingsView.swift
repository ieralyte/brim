import SwiftUI

/// Settings window. Each milestone adds its own section here.
struct SettingsView: View {
    let nowPlaying: NowPlayingService
    let battery: BatteryService

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

    private var batteryStatus: String {
        guard let snapshot = battery.snapshot else { return "No battery" }
        let state = snapshot.isCharging ? "charging" : snapshot.isPluggedIn ? "plugged in" : "on battery"
        return "\(snapshot.level)%, \(state)"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Version", value: version)
            }
            Section("Diagnostics") {
                LabeledContent("Now Playing", value: nowPlayingStatus)
                LabeledContent("Battery", value: batteryStatus)
                LabeledContent("Preview alerts") {
                    HStack {
                        Button("Charging") { battery.preview(.charging) }
                        Button("Low battery") { battery.preview(.low) }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 300)
    }
}
