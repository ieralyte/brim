import SwiftUI

/// The island's state. Views read it; `NotchWindowController` changes it.
@Observable
final class NotchViewModel {
    enum State {
        case closed
        case open
    }

    private(set) var state: State = .closed

    /// Size of the hardware notch, or of the fallback pill on screens without one.
    var closedSize: CGSize

    /// Size of the expanded island.
    let openSize = CGSize(width: 520, height: 190)

    let nowPlaying: NowPlayingService

    init(closedSize: CGSize, nowPlaying: NowPlayingService) {
        self.closedSize = closedSize
        self.nowPlaying = nowPlaying
    }

    var isOpen: Bool { state == .open }

    /// While music plays, the closed island grows a "wing" either side of the notch.
    var showsLiveActivity: Bool { nowPlaying.isPlaying }

    var wingWidth: CGFloat { closedSize.height + 12 }

    /// The closed island, including the Now Playing wings when they are showing.
    var closedDisplaySize: CGSize {
        showsLiveActivity
            ? CGSize(width: closedSize.width + wingWidth * 2, height: closedSize.height)
            : closedSize
    }

    var currentSize: CGSize { isOpen ? openSize : closedDisplaySize }

    /// Corner radius of the outward "ears" where the island meets the top of the screen.
    var earRadius: CGFloat { isOpen ? 14 : 6 }

    /// Corner radius of the island's bottom corners.
    var bottomRadius: CGFloat { isOpen ? 28 : 12 }

    func open() {
        guard state != .open else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            state = .open
        }
    }

    func close() {
        guard state != .closed else { return }
        withAnimation(.spring(response: 0.2, dampingFraction: 1.0)) {
            state = .closed
        }
    }
}
