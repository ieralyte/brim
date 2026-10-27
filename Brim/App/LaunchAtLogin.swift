import Observation
import ServiceManagement

/// Starts Brim when you log in, using macOS's own login item service.
/// The item appears in System Settings → General → Login Items, where it can also be turned off.
@Observable
final class LaunchAtLogin {
    private(set) var isEnabled = false
    /// Registered, but waiting for the user to allow it in System Settings.
    private(set) var needsApproval = false
    private(set) var errorMessage: String?

    init() {
        refresh()
    }

    /// Re-reads the status, which can change in System Settings while Brim runs.
    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        needsApproval = status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
