import SwiftUI

/// Settings window. Each milestone adds its own section here.
struct SettingsView: View {
    let nowPlaying: NowPlayingService
    let battery: BatteryService
    @Bindable var lockScreen: LockScreenController
    let launchAtLogin: LaunchAtLogin

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
        case .unavailable: "Unavailable" + (lockScreen.unavailableReason.map { " (\($0))" } ?? "")
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
                Toggle("Start Brim at login", isOn: Binding(
                    get: { launchAtLogin.isEnabled || launchAtLogin.needsApproval },
                    set: { launchAtLogin.setEnabled($0) }
                ))
                if launchAtLogin.needsApproval {
                    LabeledContent {
                        Button("Open Login Items") { launchAtLogin.openLoginItemsSettings() }
                    } label: {
                        Text("Allow Brim in System Settings to finish turning this on.")
                            .foregroundStyle(.secondary)
                    }
                }
                if let message = launchAtLogin.errorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
            Section {
                Toggle("Show on lock screen", isOn: $lockScreen.isEnabled)
                    .disabled(lockScreen.status == .unavailable)
                Picker("Keep the screen on while locked", selection: $lockScreen.keepAwake) {
                    ForEach(LockScreenController.KeepAwake.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                Toggle("Only when plugged in", isOn: $lockScreen.keepAwakeOnlyWhenPluggedIn)
                    .disabled(lockScreen.keepAwake == .never)
            } footer: {
                Text("Now Playing controls and battery level, before you log in. macOS turns the lock screen off after about 30 seconds unless Brim keeps it on.")
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
        .frame(width: 460, height: 520)
        .onAppear { launchAtLogin.refresh() }
    }
}
