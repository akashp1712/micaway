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

/// Bounds for the continuous sensitivity slider. The slider stores the
/// "mute past this angle" enter threshold directly; a smaller angle means
/// higher sensitivity (reacts to smaller turns).
public enum SensitivityLimits {
    /// Highest sensitivity — smallest turn that still counts as turning away.
    public static let minDegrees: Double = 25
    /// Lowest sensitivity — a big, deliberate turn is required.
    public static let maxDegrees: Double = 65
    /// Matches the Medium preset feel, and the historical default.
    public static let defaultDegrees: Double = 45

    /// Clamps an arbitrary angle into the supported range.
    public static func clamp(_ degrees: Double) -> Double {
        min(max(degrees, minDegrees), maxDegrees)
    }
}

public extension TurnawayConfiguration {
    /// Builds a configuration from a single "mute past this angle" value.
    ///
    /// The exit threshold and dwell times scale with the enter angle so the
    /// hysteresis and debounce feel consistent across the slider: a bigger,
    /// less-sensitive turn also gets a slightly longer dwell (you mean it),
    /// while a small, sensitive turn reacts faster. Anchored so 45° reproduces
    /// the Medium preset's feel.
    static func forTurnAngle(enterThresholdDegrees rawDegrees: Double) -> TurnawayConfiguration {
        let enter = SensitivityLimits.clamp(rawDegrees)
        let exit = (enter * 0.62).rounded()
        let span = SensitivityLimits.maxDegrees - SensitivityLimits.minDegrees
        let t = (enter - SensitivityLimits.minDegrees) / span
        return TurnawayConfiguration(
            enterThresholdDegrees: enter,
            exitThresholdDegrees: exit,
            enterDwellSeconds: 0.24 + t * (0.50 - 0.24),
            exitDwellSeconds: 0.34 + t * (0.40 - 0.34)
        )
    }
}
