import SwiftUI

/// The tabs on the right of the open island.
enum SidePane: String, CaseIterable, Identifiable {
    case tray
    case lyrics

    static let defaultsKey = "island.sidePane"

    var id: Self { self }

    var title: String {
        switch self {
        case .tray: "Tray"
        case .lyrics: "Lyrics"
        }
    }
}

/// Right-hand column of the open island: the file tray, or lyrics when they're turned on.
struct SidePaneView: View {
    let model: NotchViewModel

    var body: some View {
        let pane = model.visibleSidePane

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 2) {
                if model.lyrics.isEnabled {
                    ForEach(SidePane.allCases) { tab in
                        SidePaneTab(title: tab.title, isSelected: tab == pane) { model.sidePane = tab }
                    }
                } else {
                    Text("Tray")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer(minLength: 4)
                if pane == .tray, !model.tray.items.isEmpty {
                    Button("Clear") { model.tray.clear() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(height: 18)

            switch pane {
            case .tray:
                FileTrayView(tray: model.tray)
            case .lyrics:
                LyricsPaneView(lyrics: model.lyrics, nowPlaying: model.nowPlaying)
            }
        }
    }
}

private struct SidePaneTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(isSelected ? 0.95 : 0.45))
                .padding(.horizontal, 8)
                .frame(height: 18)
                .background(.white.opacity(isSelected ? 0.14 : 0), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
