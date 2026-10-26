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
                NowPlayingExpandedView(service: model.nowPlaying)
                    .padding(.top, model.closedSize.height + 8)
                    .padding(.horizontal, ear + 22)
                    .padding(.bottom, 18)
                    .frame(width: size.width + ear * 2, height: size.height)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            } else if model.showsLiveActivity {
                CompactNowPlayingView(service: model.nowPlaying,
                                      wingWidth: model.wingWidth,
                                      height: size.height)
                    .frame(width: size.width)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.showsLiveActivity)
    }
}
