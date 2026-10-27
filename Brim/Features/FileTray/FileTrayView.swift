import SwiftUI

/// The tray in the open island's side pane. Drag files out, double-click to open,
/// hover to reveal the remove button.
struct FileTrayView: View {
    let tray: FileTrayService

    var body: some View {
        Group {
            if tray.items.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 18, weight: .medium))
                    Text("Drop files here")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.white.opacity(0.45))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 4)], spacing: 6) {
                        ForEach(tray.items) { item in
                            TrayItemView(item: item,
                                         onOpen: { tray.open(item) },
                                         onRemove: { tray.remove(item) })
                        }
                    }
                    // Room for the remove buttons, which sit over each item's corner,
                    // so the scroll view's edge doesn't clip them.
                    .padding(.top, 6)
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

private struct TrayItemView: View {
    let item: TrayItem
    let onOpen: () -> Void
    let onRemove: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 2) {
            Image(nsImage: item.icon)
                .resizable()
                .frame(width: 34, height: 34)
            Text(item.name)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(width: 50)
        .padding(.vertical, 2)
        .background(.white.opacity(isHovering ? 0.08 : 0),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if isHovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.black, .white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .offset(x: 3, y: -3)
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture(count: 2, perform: onOpen)
        .onDrag { NSItemProvider(contentsOf: item.url) ?? NSItemProvider() }
        .help(item.url.path)
    }
}

/// Covers the open island while a file is dragged over it.
struct TrayDropOverlay: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.black.opacity(0.85))
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            VStack(spacing: 6) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 24, weight: .medium))
                    .symbolEffect(.bounce, options: .repeating)
                Text("Drop to keep in the tray")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
        }
    }
}
