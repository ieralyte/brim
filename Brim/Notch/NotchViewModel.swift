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

    init(closedSize: CGSize) {
        self.closedSize = closedSize
    }

    var isOpen: Bool { state == .open }

    var currentSize: CGSize { isOpen ? openSize : closedSize }

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
