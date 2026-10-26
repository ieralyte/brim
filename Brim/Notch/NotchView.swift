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
                ExpandedPlaceholder()
                    .padding(.top, model.closedSize.height + 6)
                    .padding(.horizontal, ear + 18)
                    .padding(.bottom, 18)
                    .frame(width: size.width + ear * 2, height: size.height)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

/// Stand-in content for the expanded island until the feature modules land.
private struct ExpandedPlaceholder: View {
    var body: some View {
        HStack(spacing: 10) {
            tile(symbol: "music.note", title: "Now Playing", milestone: "v0.2")
            tile(symbol: "tray.and.arrow.down", title: "File Tray", milestone: "v0.3")
            tile(symbol: "battery.100percent.bolt", title: "Battery", milestone: "v0.3")
        }
    }

    private func tile(symbol: String, title: String, milestone: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .medium))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
            Text("Coming in \(milestone)")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    let model = NotchViewModel(closedSize: CGSize(width: 185, height: 32))
    model.open()
    return NotchView(model: model)
        .frame(width: 600, height: 230)
        .background(.gray)
}
