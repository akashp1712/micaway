import Foundation

/// How far the user must turn their head before MicAway treats it as a
/// deliberate "turned away" gesture. Lower sensitivity needs a bigger, more
/// sustained turn — better for wide/multi-display setups where you glance a
/// lot; higher sensitivity reacts to smaller turns.
public enum Sensitivity: String, CaseIterable, Sendable, Identifiable {
    case low
    case medium
    case high

    public var id: String { rawValue }

    public static let `default`: Sensitivity = .medium

    /// Short label for the picker.
    public var label: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    public var configuration: TurnawayConfiguration {
        switch self {
        case .high:
            TurnawayConfiguration(
                enterThresholdDegrees: 30,
                exitThresholdDegrees: 18,
                enterDwellSeconds: 0.24,
                exitDwellSeconds: 0.34
            )
        case .medium:
            TurnawayConfiguration(
                enterThresholdDegrees: 45,
                exitThresholdDegrees: 28,
                enterDwellSeconds: 0.40,
                exitDwellSeconds: 0.34
            )
        case .low:
            TurnawayConfiguration(
                enterThresholdDegrees: 60,
                exitThresholdDegrees: 38,
                enterDwellSeconds: 0.50,
                exitDwellSeconds: 0.40
            )
        }
    }
}
