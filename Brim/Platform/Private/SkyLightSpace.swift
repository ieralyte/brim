import AppKit
import os

/// Shows windows above the lock screen using Apple's private SkyLight window server API.
///
/// It creates a window-server "space" pinned at the level macOS uses for notifications on
/// the lock screen, then moves windows into it. The technique comes from SkyLightWindow
/// by Lakr Aream (MIT License, https://github.com/Lakr233/SkyLightWindow).
///
/// Every symbol is looked up at runtime. If a macOS update removes or renames one,
/// `init` throws and Brim turns the lock screen feature off instead of crashing.
final class SkyLightSpace {
    /// Why setting up the space failed, shown in Settings → Diagnostics.
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    private typealias MainConnectionID = @convention(c) () -> Int32
    private typealias SpaceCreate = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias SpaceSetAbsoluteLevel = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias ShowSpaces = @convention(c) (Int32, CFArray) -> Int32
    private typealias AddWindowsAndRemoveFromSpaces = @convention(c) (Int32, Int32, CFArray, Int32) -> Int32

    /// `kSLSSpaceAbsoluteLevelNotificationCenterAtScreenLock`: just above the lock screen itself.
    private static let lockScreenNotificationLevel: Int32 = 400
    private static let log = Logger(subsystem: "io.github.brim.Brim", category: "SkyLight")

    private let connection: Int32
    private let space: Int32
    private let addWindows: AddWindowsAndRemoveFromSpaces

    init() throws {
        let path = "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight"
        guard let handle = dlopen(path, RTLD_NOW) else {
            throw Failure(description: "SkyLight framework not found")
        }
        let mainConnectionID = try Self.symbol(handle, "SLSMainConnectionID", as: MainConnectionID.self)
        let spaceCreate = try Self.symbol(handle, "SLSSpaceCreate", as: SpaceCreate.self)
        let setLevel = try Self.symbol(handle, "SLSSpaceSetAbsoluteLevel", as: SpaceSetAbsoluteLevel.self)
        let showSpaces = try Self.symbol(handle, "SLSShowSpaces", as: ShowSpaces.self)
        let addWindows = try Self.symbol(handle, "SLSSpaceAddWindowsAndRemoveFromSpaces",
                                         as: AddWindowsAndRemoveFromSpaces.self)

        let connection = mainConnectionID()
        guard connection != 0 else { throw Failure(description: "no window server connection") }
        let space = spaceCreate(connection, 1, 0)
        guard space != 0 else { throw Failure(description: "could not create a space") }

        // These two can report an error and still take effect (SkyLightWindow ignores both),
        // so they are logged rather than treated as fatal.
        let levelResult = setLevel(connection, space, Self.lockScreenNotificationLevel)
        let showResult = showSpaces(connection, [space] as CFArray)
        if levelResult != 0 || showResult != 0 {
            Self.log.notice("SkyLight setup returned level=\(levelResult) show=\(showResult); continuing")
        }

        self.connection = connection
        self.space = space
        self.addWindows = addWindows
    }

    /// Moves `window` into the lock screen space. The window must already be on screen.
    @discardableResult
    func add(_ window: NSWindow) -> Bool {
        let result = addWindows(connection, space, [window.windowNumber] as CFArray, 7)
        if result != 0 {
            Self.log.error("SLSSpaceAddWindowsAndRemoveFromSpaces returned \(result)")
        }
        return result == 0
    }

    private static func symbol<T>(_ handle: UnsafeMutableRawPointer, _ name: String, as type: T.Type) throws -> T {
        guard let pointer = dlsym(handle, name) else {
            throw Failure(description: "\(name) is missing")
        }
        return unsafeBitCast(pointer, to: type)
    }
}
