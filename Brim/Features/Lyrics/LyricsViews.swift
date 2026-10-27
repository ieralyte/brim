import SwiftUI

/// One line of lyrics. Swaps instantly when the line changes (no fade, so it never looks late),
/// and keeps the same height between lines so nothing jumps.
struct LyricLineView: View {
    let text: String?
    let size: CGFloat
    let weight: Font.Weight
    let lineLimit: Int

    var body: some View {
        Text(text ?? " ")
            .font(.system(size: size, weight: weight))
            .lineLimit(lineLimit, reservesSpace: true)
            .truncationMode(.tail)
            .transaction { $0.animation = nil }
            .accessibilityLabel(text ?? "")
    }
}

/// Scrolling lyrics for the island's side pane. The line being sung is bright and kept
/// in the middle; click any line to jump there.
struct LyricsPaneView: View {
    let lyrics: LyricsService
    let nowPlaying: NowPlayingService

    var body: some View {
        switch lyrics.state {
        case .synced:
            SyncedLyricsList(lyrics: lyrics) { nowPlaying.seek(to: $0) }
        case .unsynced:
            ScrollView(showsIndicators: false) {
                Text(lyrics.plainLines.joined(separator: "\n"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            .mask(EdgeFade())
        default:
            LyricsMessage(state: lyrics.state)
        }
    }
}

private struct SyncedLyricsList: View {
    let lyrics: LyricsService
    let onSeek: (TimeInterval) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                // Not lazy: every line's height is known up front, so scrolling to a line glides
                // straight there instead of correcting itself as rows are measured.
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(lyrics.lines.enumerated()), id: \.offset) { index, line in
                        let isCurrent = index == lyrics.currentIndex
                        Button { onSeek(line.time) } label: {
                            Text(line.text.isEmpty ? "♪" : line.text)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(isCurrent ? 1 : 0.32))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .transaction { $0.animation = nil } // highlight switches instantly, on the beat
                        .id(index)
                    }
                }
                // Room so the first and last lines can sit in the middle too.
                .padding(.vertical, 40)
            }
            .mask(EdgeFade())
            .onAppear { proxy.scrollTo(lyrics.currentIndex ?? 0, anchor: .center) }
            .onChange(of: lyrics.currentIndex) { _, index in
                // A slow, critically damped glide: starts gently, settles without bouncing.
                withAnimation(.smooth(duration: 0.6)) {
                    proxy.scrollTo(index ?? 0, anchor: .center)
                }
            }
        }
    }
}

private struct LyricsMessage: View {
    let state: LyricsService.State

    private var content: (symbol: String, text: String) {
        switch state {
        case .loading: ("ellipsis", "Looking for lyrics…")
        case .instrumental: ("music.note", "Instrumental")
        case .notFound: ("text.badge.xmark", "No lyrics for this song")
        case .failed: ("wifi.exclamationmark", "Couldn't reach LRCLIB")
        default: ("quote.bubble", "Play a song to see its lyrics")
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: content.symbol)
                .font(.system(size: 16, weight: .medium))
            Text(content.text)
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white.opacity(0.45))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Fades content out at the top and bottom edges of a scroll view.
private struct EdgeFade: View {
    var body: some View {
        LinearGradient(stops: [.init(color: .clear, location: 0),
                               .init(color: .black, location: 0.18),
                               .init(color: .black, location: 0.82),
                               .init(color: .clear, location: 1)],
                       startPoint: .top, endPoint: .bottom)
    }
}
