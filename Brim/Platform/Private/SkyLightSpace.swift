import AppKit

/// Shows windows above the lock screen using Apple's private SkyLight window server API.
///
/// It creates a window-server "space" pinned at the level macOS uses for notifications on
/// the lock screen, then moves windows into it. The technique comes from SkyLightWindow
/// by Lakr Aream (MIT License, https://github.com/Lakr233/SkyLightWindow).
///
/// Every symbol is looked up at runtime. If a macOS update removes or renames one,
/// `init` fails and Brim turns the lock screen feature off instead of crashing.
final class SkyLightSpace {
    private typealias MainConnectionID = @convention(c) () -> Int32
    private typealias SpaceCreate = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias SpaceSetAbsoluteLevel = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias ShowSpaces = @convention(c) (Int32, CFArray) -> Int32
    private typealias AddWindowsAndRemoveFromSpaces = @convention(c) (Int32, Int32, CFArray, Int32) -> Int32

    /// `kSLSSpaceAbsoluteLevelNotificationCenterAtScreenLock`: just above the lock screen itself.
    private static let lockScreenNotificationLevel: Int32 = 400

    private let connection: Int32
    private let space: Int32
    private let addWindows: AddWindowsAndRemoveFromSpaces

    init?() {
        let path = "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight"
        guard let handle = dlopen(path, RTLD_NOW),
              let mainConnectionID = Self.symbol(handle, "SLSMainConnectionID", as: MainConnectionID.self),
              let spaceCreate = Self.symbol(handle, "SLSSpaceCreate", as: SpaceCreate.self),
              let setLevel = Self.symbol(handle, "SLSSpaceSetAbsoluteLevel", as: SpaceSetAbsoluteLevel.self),
              let showSpaces = Self.symbol(handle, "SLSShowSpaces", as: ShowSpaces.self),
              let addWindows = Self.symbol(handle, "SLSSpaceAddWindowsAndRemoveFromSpaces",
                                           as: AddWindowsAndRemoveFromSpaces.self)
        else { return nil }

        let connection = mainConnectionID()
        let space = spaceCreate(connection, 1, 0)
        guard connection != 0, space != 0,
              setLevel(connection, space, Self.lockScreenNotificationLevel) == 0,
              showSpaces(connection, [space] as CFArray) == 0
        else { return nil }

        self.connection = connection
        self.space = space
        self.addWindows = addWindows
    }

    /// Moves `window` into the lock screen space. The window must already be on screen.
    @discardableResult
    func add(_ window: NSWindow) -> Bool {
        addWindows(connection, space, [window.windowNumber] as CFArray, 7) == 0
    }

    private static func symbol<T>(_ handle: UnsafeMutableRawPointer, _ name: String, as type: T.Type) -> T? {
        guard let pointer = dlsym(handle, name) else { return nil }
        return unsafeBitCast(pointer, to: type)
    }
}
