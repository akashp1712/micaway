import AppKit
import Combine
import Foundation
import MicAwayCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var intentState: IntentState = .needsCalibration
    @Published private(set) var relativeYawDegrees: Double = 0
    @Published private(set) var motionStatus: HeadphoneMotionService.Status = .looking
    @Published private(set) var message = "Connect your AirPods and face your Mac."
    @Published var guardEnabled = true {
        didSet { guardEnabledChanged() }
    }
    @Published var microphoneGateEnabled: Bool {
        didSet {
            UserDefaults.standard.set(
                microphoneGateEnabled,
                forKey: Self.microphoneGateDefaultsKey
            )
            microphoneGateEnabledChanged()
        }
    }
    @Published var manualMuteEngaged = false {
        didSet {
            guard manualMuteEngaged != oldValue else { return }
            applyMuteState()
        }
    }
    @Published var sensitivity: Sensitivity {
        didSet {
            guard sensitivity != oldValue else { return }
            UserDefaults.standard.set(
                sensitivity.rawValue,
                forKey: Self.sensitivityDefaultsKey
            )
            reconfigureEngine()
        }
    }

    private var latestYawRadians: Double?
    private var engine = TurnawayEngine()
    private let motion = HeadphoneMotionService()
    private let microphone = InputMuteController()
    private static let microphoneGateDefaultsKey = "microphoneGateEnabled"
    private static let sensitivityDefaultsKey = "sensitivity"

    var canCalibrate: Bool { latestYawRadians != nil }
    var microphoneGateAvailable: Bool { microphone.canMuteInput() }
    var manualMuteAvailable: Bool { microphone.canMuteInput() }

    var statusTitle: String {
        switch intentState {
        case .needsCalibration: "Face your Mac"
        case .listening: "Listening"
        case .turnaway: "Not for your Mac"
        }
    }

    var statusDetail: String {
        switch intentState {
        case .needsCalibration:
            "Calibrate once while looking forward."
        case .listening:
            "Turn away to pause voice input."
        case .turnaway:
            "Your side conversation stays out."
        }
    }

    var menuBarSymbol: String {
        if manualMuteEngaged { return "mic.slash.fill" }
        return switch intentState {
        case .needsCalibration: "waveform.badge.exclamationmark"
        case .listening: "waveform.circle.fill"
        case .turnaway: "waveform.slash"
        }
    }

    init() {
        microphoneGateEnabled = UserDefaults.standard.object(
            forKey: Self.microphoneGateDefaultsKey
        ) as? Bool ?? true

        let storedSensitivity = UserDefaults.standard.string(
            forKey: Self.sensitivityDefaultsKey
        ).flatMap(Sensitivity.init(rawValue:)) ?? .default
        sensitivity = storedSensitivity
        engine = TurnawayEngine(configuration: storedSensitivity.configuration)

        motion.onStatus = { [weak self] status in
            self?.motionStatus = status
            switch status {
            case .looking:
                self?.message = "Put in your AirPods to begin."
            case .connected:
                self?.message = "Motion connected. Face your Mac and calibrate."
            case let .unavailable(reason):
                self?.message = reason
            }
        }
        motion.onYaw = { [weak self] yaw, isNewReferenceFrame in
            self?.ingest(yaw: yaw, isNewReferenceFrame: isNewReferenceFrame)
        }
        motion.start()
    }

    func calibrate() {
        guard let latestYawRadians else { return }
        let reading = engine.calibrate(yawRadians: latestYawRadians)
        apply(reading)
        message = "Forward set. The boundary is ready."
    }

    func retryMotion() {
        motion.retry()
    }

    func quit() {
        prepareForTermination()
        NSApplication.shared.terminate(nil)
    }

    private func ingest(yaw: Double, isNewReferenceFrame: Bool) {
        latestYawRadians = yaw
        objectWillChange.send()
        guard engine.state != .needsCalibration else { return }

        if isNewReferenceFrame {
            // The motion stream restarted (e.g. AirPods switched Bluetooth
            // profile when a call grabbed the mic), so CoreMotion gave us a new
            // yaw reference frame. Re-anchor forward to the current head
            // position instead of reading the origin jump as a turn-away.
            // Tradeoff: this fails open — if a restart lands while the user is
            // genuinely turned away, "forward" is redefined to that pose until
            // the next Calibrate. That is preferable to a false mute and self-
            // heals; it never produces a stuck state (reanchor always yields a
            // valid listening baseline).
            apply(engine.reanchor(yawRadians: yaw))
            message = "Head reference re-centered after an AirPods reconnect."
            return
        }

        apply(engine.update(yawRadians: yaw, timestamp: ProcessInfo.processInfo.systemUptime))
    }

    private func apply(_ reading: IntentReading) {
        let previousState = intentState
        intentState = guardEnabled ? reading.state : .listening
        relativeYawDegrees = reading.relativeYawDegrees

        guard previousState != intentState else { return }
        applyMuteState()
    }

    private func reconfigureEngine() {
        // Preserve the existing calibration baseline across a sensitivity change.
        let baseline = engine.baselineYawRadians
        var rebuilt = TurnawayEngine(configuration: sensitivity.configuration)
        if let baseline {
            rebuilt.calibrate(yawRadians: baseline)
        }
        engine = rebuilt

        // Re-evaluate the current head position under the new thresholds so the
        // change takes effect immediately (e.g. lowering sensitivity unmutes).
        if let latestYawRadians, engine.state != .needsCalibration {
            apply(engine.update(
                yawRadians: latestYawRadians,
                timestamp: ProcessInfo.processInfo.systemUptime
            ))
        }
    }

    private func guardEnabledChanged() {
        if !guardEnabled {
            intentState = engine.state == .needsCalibration ? .needsCalibration : .listening
        } else if engine.state != .needsCalibration {
            intentState = engine.state
        }
        applyMuteState()
    }

    private func microphoneGateEnabledChanged() {
        applyMuteState()
    }

    private func applyMuteState() {
        let shouldMute = MuteResolver.shouldMute(
            manualMuteEngaged: manualMuteEngaged,
            guardEnabled: guardEnabled,
            microphoneGateEnabled: microphoneGateEnabled,
            intentState: intentState
        )
        do {
            if shouldMute {
                try microphone.muteForTurnaway()
            } else {
                try microphone.restoreIfNeeded()
            }
        } catch {
            message = error.localizedDescription
            // Never let the menu-bar icon claim the mic is muted when the mute
            // actually failed (e.g. ⌥⌘M pressed with no mutable input device).
            if manualMuteEngaged {
                manualMuteEngaged = false
            }
        }
    }

    func prepareForTermination() {
        motion.stop()
        try? microphone.restoreIfNeeded()
    }
}
