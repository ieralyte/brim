import SwiftUI

/// Placeholder settings window. Each milestone adds its own section here.
struct SettingsView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Version", value: version)
                Text("More settings arrive with each milestone.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 180)
    }
}
