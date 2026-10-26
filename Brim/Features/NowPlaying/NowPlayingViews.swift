import SwiftUI

/// Album art, or a music-note placeholder while artwork is missing or still loading.
struct ArtworkView: View {
    let image: NSImage?
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.white.opacity(0.1)
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Shown in the closed island while music plays: artwork left of the notch, a live waveform right of it.
struct CompactNowPlayingView: View {
    let service: NowPlayingService
    let wingWidth: CGFloat
    let height: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ArtworkView(image: service.artwork, size: height - 10, cornerRadius: 5)
                .frame(width: wingWidth)
            Spacer(minLength: 0)
            Image(systemName: "waveform")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.variableColor.iterative.dimInactiveLayers, isActive: service.isPlaying)
                .frame(width: wingWidth)
        }
        .frame(height: height)
    }
}

/// The expanded player: artwork, track details, scrubber and controls.
struct NowPlayingExpandedView: View {
    let service: NowPlayingService

    var body: some View {
        if let info = service.info {
            HStack(spacing: 16) {
                ArtworkView(image: service.artwork, size: 92, cornerRadius: 14)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(info.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(info.artist ?? info.album ?? " ")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .lineLimit(1)

                    if info.duration > 0 {
                        ScrubberView(info: info) { service.seek(to: $0) }
                    }

                    PlaybackControls(service: service)
                        .frame(maxWidth: .infinity)
                }
            }
        } else {
            EmptyNowPlayingView(status: service.status)
        }
    }
}

private struct EmptyNowPlayingView: View {
    let status: NowPlayingService.Status

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: status == .unavailable ? "exclamationmark.triangle" : "music.note")
                .font(.system(size: 22, weight: .medium))
            Text(status == .unavailable ? "Now Playing is unavailable" : "Nothing playing")
                .font(.system(size: 13, weight: .semibold))
            Text(status == .unavailable
                 ? "This macOS version blocked the media adapter."
                 : "Play something in Music, Spotify or your browser.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PlaybackControls: View {
    let service: NowPlayingService

    var body: some View {
        HStack(spacing: 32) {
            ControlButton(symbol: "backward.fill", size: 16) { service.previousTrack() }
            ControlButton(symbol: service.isPlaying ? "pause.fill" : "play.fill", size: 22) {
                service.togglePlayPause()
            }
            ControlButton(symbol: "forward.fill", size: 16) { service.nextTrack() }
        }
    }
}

private struct ControlButton: View {
    let symbol: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 36, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.6 : 1))
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Progress bar with times. It grows while you drag it and seeks when you let go.
/// Redraws once a second, never faster.
struct ScrubberView: View {
    let info: NowPlayingInfo
    let onSeek: (TimeInterval) -> Void

    @State private var dragFraction: Double?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = info.elapsed(at: context.date)
            let fraction = dragFraction ?? (elapsed / info.duration)
            let shown = dragFraction.map { $0 * info.duration } ?? elapsed

            VStack(spacing: 3) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.2))
                        Capsule().fill(.white)
                            .frame(width: geometry.size.width * clamp(fraction))
                    }
                    .frame(height: dragFraction == nil ? 4 : 8)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                dragFraction = clamp(value.location.x / geometry.size.width)
                            }
                            .onEnded { value in
                                onSeek(clamp(value.location.x / geometry.size.width) * info.duration)
                                dragFraction = nil
                            }
                    )
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: dragFraction == nil)
                }
                .frame(height: 12)

                HStack {
                    Text(format(shown))
                    Spacer()
                    Text("-" + format(info.duration - shown))
                }
                .font(.system(size: 10, weight: .medium).monospacedDigit())
                .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private func format(_ seconds: TimeInterval) -> String {
        let total = Int(max(seconds, 0).rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%d:%02d", minutes, secs)
    }
}
