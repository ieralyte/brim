import IOKit.pwr_mgt

/// Asks macOS not to turn the display off for inactivity, the same public power
/// assertion video players and `caffeinate -d` use. It also keeps the lock screen lit.
final class DisplayWakeAssertion {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isHeld = false

    func hold(reason: String) {
        guard !isHeld else { return }
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )
        isHeld = result == kIOReturnSuccess
    }

    func release() {
        guard isHeld else { return }
        IOPMAssertionRelease(assertionID)
        isHeld = false
    }
}
