import SwiftUI

/// Root view of the notch panel. The panel is sized for the open island;
/// this view draws the island at its current size, pinned to the top centre.
struct NotchView: View {
    let model: NotchViewModel

    var body: some View {
        let ear = model.earRadius
        let size = model.currentSize

        ZStack(alignment: .top) {
            NotchShape(topCornerRadius: ear, bottomCornerRadius: model.bottomRadius)
                .fill(.black)
                .frame(width: size.width + ear * 2, height: size.height)
                .shadow(color: .black.opacity(model.isOpen ? 0.45 : 0), radius: 14, y: 6)

            if model.isOpen {
                ExpandedIslandView(model: model)
                    .padding(.top, model.closedSize.height + 8)
                    .padding(.horizontal, ear + 22)
                    .padding(.bottom, 18)
                    .frame(width: size.width + ear * 2, height: size.height)
                    .overlay(alignment: .topTrailing) {
                        if let snapshot = model.battery.snapshot {
                            BatteryIndicator(snapshot: snapshot)
                                .frame(height: model.closedSize.height)
                                .padding(.trailing, ear + 24)
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            } else if let activity = model.liveActivity {
                Group {
                    switch activity {
                    case .battery(let alert):
                        BatteryAlertView(alert: alert, wingWidth: model.wingWidth, height: size.height)
                    case .nowPlaying:
                        CompactNowPlayingView(service: model.nowPlaying,
                                              wingWidth: model.wingWidth,
                                              height: size.height)
                    }
                }
                .frame(width: size.width)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.liveActivity)
    }
}

/// The open island: Now Playing on the left, the file tray on the right.
/// The whole island accepts dropped files.
private struct ExpandedIslandView: View {
    let model: NotchViewModel
    @State private var isDropTargeted = false

    var body: some View {
        HStack(spacing: 16) {
            NowPlayingExpandedView(service: model.nowPlaying)
                .frame(maxWidth: .infinity)
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 1)
            FileTrayView(tray: model.tray)
                .frame(width: 168)
        }
        .contentShape(Rectangle())
        .overlay {
            if isDropTargeted {
                TrayDropOverlay()
                    .transition(.opacity)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            model.tray.add(urls)
            return !urls.isEmpty
        } isTargeted: { targeted in
            withAnimation(.easeOut(duration: 0.15)) { isDropTargeted = targeted }
        }
    }
}
