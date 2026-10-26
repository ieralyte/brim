import SwiftUI

/// The lock screen card: Now Playing with a progress bar and controls, plus battery level.
/// Falls back to a small battery pill when nothing is playing.
struct LockScreenView: View {
    let nowPlaying: NowPlayingService
    let battery: BatteryService

    var body: some View {
        VStack {
            if let info = nowPlaying.info {
                HStack(spacing: 14) {
                    ArtworkView(image: nowPlaying.artwork, size: 84, cornerRadius: 14)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(info.title)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(info.artist ?? info.album ?? " ")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .lineLimit(1)
                            Spacer(minLength: 8)
                            if let snapshot = battery.snapshot {
                                BatteryIndicator(snapshot: snapshot)
                            }
                        }

                        // Same scrubber as the open island: drag it to seek, even while locked.
                        if info.duration > 0 {
                            ScrubberView(info: info) { nowPlaying.seek(to: $0) }
                        }

                        HStack(spacing: 28) {
                            LockScreenButton(symbol: "backward.fill", size: 15) { nowPlaying.previousTrack() }
                            LockScreenButton(symbol: nowPlaying.isPlaying ? "pause.fill" : "play.fill", size: 20) {
                                nowPlaying.togglePlayPause()
                            }
                            LockScreenButton(symbol: "forward.fill", size: 15) { nowPlaying.nextTrack() }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .foregroundStyle(.white)
                .padding(16)
                .frame(width: 400)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else if let snapshot = battery.snapshot {
                BatteryIndicator(snapshot: snapshot)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: nowPlaying.info == nil)
    }
}

private struct LockScreenButton: View {
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
        .buttonStyle(.plain)
    }
}
