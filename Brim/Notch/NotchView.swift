import SwiftUI

/// Root view of the notch panel. The panel is sized for the open island;
/// this view draws the island at its current size, pinned to the top centre.
struct NotchView: View {
    let model: NotchViewModel

    var body: some View {
        let ear = model.earRadius
        let size = model.currentSize
        // Over a real notch the island hangs from the top edge in the notch's shape.
        // Elsewhere it floats just below the edge as a pill, like the Dynamic Island.
        let floating = !model.hasHardwareNotch
        let inset = model.floatInset
        let shapeHeight = floating && !model.isOpen ? size.height - inset * 2 : size.height

        ZStack(alignment: .top) {
            Group {
                if floating {
                    RoundedRectangle(cornerRadius: model.isOpen ? 28 : shapeHeight / 2, style: .continuous)
                        .fill(.black)
                        .frame(width: size.width, height: shapeHeight)
                } else {
                    NotchShape(topCornerRadius: ear, bottomCornerRadius: model.bottomRadius)
                        .fill(.black)
                        .frame(width: size.width + ear * 2, height: size.height)
                }
            }
            .shadow(color: .black.opacity(model.isOpen ? 0.45 : (floating ? 0.3 : 0)),
                    radius: model.isOpen ? 14 : 4, y: model.isOpen ? 6 : 1)
            .padding(.top, inset)
            .opacity(model.isIslandVisible ? 1 : 0)

            if model.isOpen {
                ExpandedIslandView(model: model)
                    .padding(.top, model.closedSize.height + 8 + inset)
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
                        BatteryAlertView(alert: alert, wingWidth: model.wingWidth, height: shapeHeight)
                    case .nowPlaying:
                        CompactNowPlayingView(service: model.nowPlaying,
                                              wingWidth: model.wingWidth,
                                              height: shapeHeight)
                    }
                }
                .frame(width: size.width)
                .padding(.top, inset)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.liveActivity)
        .animation(.easeOut(duration: 0.2), value: model.isIslandVisible)
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
            SidePaneView(model: model)
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
            if targeted { model.sidePane = .tray } // show where the files will land
        }
    }
}
