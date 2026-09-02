import Foundation

public enum IntentState: String, Equatable, Sendable {
    case needsCalibration
    case listening
    case turnaway
}

public struct TurnawayConfiguration: Equatable, Sendable {
    public var enterThresholdDegrees: Double
    public var exitThresholdDegrees: Double
    public var enterDwellSeconds: TimeInterval
    public var exitDwellSeconds: TimeInterval

    public init(
        enterThresholdDegrees: Double = 45,
        exitThresholdDegrees: Double = 28,
        enterDwellSeconds: TimeInterval = 0.40,
        exitDwellSeconds: TimeInterval = 0.34
    ) {
        precondition(enterThresholdDegrees > exitThresholdDegrees)
        precondition(exitThresholdDegrees >= 0)
        precondition(enterDwellSeconds >= 0 && exitDwellSeconds >= 0)
        self.enterThresholdDegrees = enterThresholdDegrees
        self.exitThresholdDegrees = exitThresholdDegrees
        self.enterDwellSeconds = enterDwellSeconds
        self.exitDwellSeconds = exitDwellSeconds
    }
}

public struct IntentReading: Equatable, Sendable {
    public let state: IntentState
    public let relativeYawDegrees: Double

    public init(state: IntentState, relativeYawDegrees: Double) {
        self.state = state
        self.relativeYawDegrees = relativeYawDegrees
    }
}

public struct TurnawayEngine: Sendable {
    private enum Candidate: Sendable {
        case turnaway(since: TimeInterval)
        case listening(since: TimeInterval)
    }

    public let configuration: TurnawayConfiguration
    public private(set) var state: IntentState = .needsCalibration
    public private(set) var baselineYawRadians: Double?
    private var candidate: Candidate?

    public init(configuration: TurnawayConfiguration = .init()) {
        self.configuration = configuration
    }

    @discardableResult
    public mutating func calibrate(yawRadians: Double) -> IntentReading {
        baselineYawRadians = Self.normalized(yawRadians)
        state = .listening
        candidate = nil
        return IntentReading(state: state, relativeYawDegrees: 0)
    }

    public mutating func reset() {
        baselineYawRadians = nil
        state = .needsCalibration
        candidate = nil
    }

    /// Re-anchors the calibrated forward to a new motion reference frame.
    ///
    /// `CMHeadphoneMotionManager` captures a fresh yaw origin every time the
    /// motion stream (re)starts — for example when AirPods switch Bluetooth
    /// profile as a call grabs the microphone. The previous baseline is
    /// meaningless in the new frame, so we adopt the current head position as
    /// forward and return to listening rather than reading the origin jump as
    /// a turn-away. No-op (and no baseline is set) if the engine has never
    /// been calibrated — the user must set forward first.
    @discardableResult
    public mutating func reanchor(yawRadians: Double) -> IntentReading {
        guard baselineYawRadians != nil else {
            return IntentReading(state: state, relativeYawDegrees: 0)
        }
        return calibrate(yawRadians: yawRadians)
    }

    public mutating func update(
        yawRadians: Double,
        timestamp: TimeInterval
    ) -> IntentReading {
        guard let baselineYawRadians else {
            return IntentReading(state: .needsCalibration, relativeYawDegrees: 0)
        }

        let relativeRadians = Self.normalized(yawRadians - baselineYawRadians)
        let relativeDegrees = relativeRadians * 180 / .pi
        let magnitude = abs(relativeDegrees)

        switch state {
        case .needsCalibration:
            state = .listening
            candidate = nil

        case .listening:
            if magnitude >= configuration.enterThresholdDegrees {
                if case let .turnaway(since) = candidate {
                    if timestamp - since >= configuration.enterDwellSeconds {
                        state = .turnaway
                        candidate = nil
                    }
                } else {
                    candidate = .turnaway(since: timestamp)
                }
            } else {
                candidate = nil
            }

        case .turnaway:
            if magnitude <= configuration.exitThresholdDegrees {
                if case let .listening(since) = candidate {
                    if timestamp - since >= configuration.exitDwellSeconds {
                        state = .listening
                        candidate = nil
                    }
                } else {
                    candidate = .listening(since: timestamp)
                }
            } else {
                candidate = nil
            }
        }

        return IntentReading(state: state, relativeYawDegrees: relativeDegrees)
    }

    private static func normalized(_ radians: Double) -> Double {
        atan2(sin(radians), cos(radians))
    }
}
