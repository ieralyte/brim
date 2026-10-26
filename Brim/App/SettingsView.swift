import SwiftUI

/// Settings window. Each milestone adds its own section here.
struct SettingsView: View {
    let nowPlaying: NowPlayingService
    let battery: BatteryService
    @Bindable var lockScreen: LockScreenController

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

    private var lockScreenStatus: String {
        switch lockScreen.status {
        case .ready: "Working"
        case .off: "Off"
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
            Section {
                Toggle("Show on lock screen", isOn: $lockScreen.isEnabled)
                    .disabled(lockScreen.status == .unavailable)
            } footer: {
                Text("Now Playing controls and battery level, before you log in.")
                    .foregroundStyle(.secondary)
            }
            Section("Diagnostics") {
                LabeledContent("Now Playing", value: nowPlayingStatus)
                LabeledContent("Battery", value: batteryStatus)
                LabeledContent("Lock screen", value: lockScreenStatus)
                LabeledContent("Preview alerts") {
                    HStack {
                        Button("Charging") { battery.preview(.charging) }
                        Button("Low battery") { battery.preview(.low) }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 400)
    }
}
