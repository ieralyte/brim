import Foundation
import IOKit.ps
import Observation

/// A short notice shown in the closed island.
struct BatteryAlert: Equatable {
    enum Kind {
        case charging
        case low
    }

    let kind: Kind
    let level: Int
}

/// Battery level and charging state, updated when macOS reports a power change.
/// It never polls: IOKit calls back on the main run loop when anything changes.
@Observable
final class BatteryService {
    struct Snapshot: Equatable {
        var level: Int
        var isCharging: Bool
        var isPluggedIn: Bool
    }

    /// `nil` on Macs without a battery.
    private(set) var snapshot: Snapshot?

    /// Called when the island should show a charging or low-battery notice.
    @ObservationIgnored var onAlert: ((BatteryAlert) -> Void)?

    /// Alert once as the level drops through each of these, while on battery.
    static let lowThresholds = [20, 10]

    @ObservationIgnored private var runLoopSource: CFRunLoopSource?
    @ObservationIgnored private var alertedThresholds: Set<Int> = []

    func start() {
        guard runLoopSource == nil else { return }
        update(with: Self.read(), isInitial: true)

        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let service = Unmanaged<BatteryService>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { service.refresh() }
        }, context)?.takeRetainedValue() else { return }

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        runLoopSource = source
    }

    func refresh() {
        update(with: Self.read(), isInitial: false)
    }

    /// Shows an alert without a real power change, for checking how it looks.
    func preview(_ kind: BatteryAlert.Kind) {
        let level = snapshot?.level ?? (kind == .low ? 10 : 80)
        onAlert?(BatteryAlert(kind: kind, level: kind == .low ? min(level, 10) : level))
    }

    // MARK: - Private

    private func update(with new: Snapshot?, isInitial: Bool) {
        let old = snapshot
        guard new != old else { return }
        snapshot = new
        guard let new else { return }

        if new.isPluggedIn {
            alertedThresholds.removeAll()
            if !isInitial, old?.isPluggedIn == false {
                onAlert?(BatteryAlert(kind: .charging, level: new.level))
            }
            return
        }

        // On battery: alert for the lowest threshold just crossed.
        let crossed = Self.lowThresholds.filter { new.level <= $0 && !alertedThresholds.contains($0) }
        guard !crossed.isEmpty else { return }
        alertedThresholds.formUnion(crossed)
        if !isInitial, let threshold = crossed.min() {
            onAlert?(BatteryAlert(kind: .low, level: min(new.level, threshold)))
        }
    }

    /// Reads the internal battery from IOKit, or `nil` if there is none.
    private static func read() -> Snapshot? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?
                .takeUnretainedValue() as? [String: Any],
                  description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
            else { continue }

            let current = description[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maximum = description[kIOPSMaxCapacityKey] as? Int ?? 100
            let level = maximum > 0 ? Int((Double(current) / Double(maximum) * 100).rounded()) : current
            return Snapshot(
                level: min(max(level, 0), 100),
                isCharging: description[kIOPSIsChargingKey] as? Bool ?? false,
                isPluggedIn: description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
            )
        }
        return nil
    }
}
