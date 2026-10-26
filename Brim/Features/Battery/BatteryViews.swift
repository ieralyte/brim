import SwiftUI

/// Battery level shown in the top corner of the open island.
struct BatteryIndicator: View {
    let snapshot: BatteryService.Snapshot

    private var symbol: String {
        if snapshot.isPluggedIn { return "battery.100percent.bolt" }
        switch snapshot.level {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    private var tint: Color {
        if snapshot.isPluggedIn { return .green }
        return snapshot.level <= 20 ? .red : .white
    }

    var body: some View {
        HStack(spacing: 5) {
            Text("\(snapshot.level)%")
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
            Image(systemName: symbol)
                .font(.system(size: 14))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
        }
    }
}

/// The closed island's charging or low-battery notice: an icon left of the notch, the level right of it.
struct BatteryAlertView: View {
    let alert: BatteryAlert
    let wingWidth: CGFloat
    let height: CGFloat

    private var tint: Color { alert.kind == .charging ? .green : .red }

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: alert.kind == .charging ? "bolt.fill" : "battery.25percent")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .symbolEffect(.pulse, options: .repeating)
                .frame(width: wingWidth)
            Spacer(minLength: 0)
            Text("\(alert.level)%")
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(tint)
                .frame(width: wingWidth)
        }
        .frame(height: height)
    }
}
