import AppKit

extension NSScreen {
    /// Size of the hardware notch in points, or `nil` if this screen has none.
    ///
    /// macOS reports the menu bar areas either side of the notch
    /// (`auxiliaryTopLeftArea` / `auxiliaryTopRightArea`); the notch is the gap between them.
    var notchSize: CGSize? {
        guard safeAreaInsets.top > 0,
              let left = auxiliaryTopLeftArea?.width,
              let right = auxiliaryTopRightArea?.width
        else { return nil }
        return CGSize(width: frame.width - left - right, height: safeAreaInsets.top)
    }

    /// Height of the menu bar on this screen (0 when it is auto-hidden).
    var menuBarHeight: CGFloat {
        frame.maxY - visibleFrame.maxY
    }

    /// The built-in display with a notch, if one is connected.
    static var withNotch: NSScreen? {
        screens.first { $0.notchSize != nil }
    }

    /// Where Brim lives: the notched display if there is one, otherwise the primary
    /// display (the one set as main in System Settings → Displays, which holds the
    /// menu bar). Not `NSScreen.main`, which follows whichever screen has focus.
    static var brimHome: NSScreen? {
        withNotch ?? screens.first
    }
}
