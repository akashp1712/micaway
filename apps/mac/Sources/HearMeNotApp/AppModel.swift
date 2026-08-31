import AppKit
import Combine
import Foundation
import HearMeNotCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var intentState: IntentState = .needsCalibration
    @Published private(set) var relativeYawDegrees: Double = 0
    @Published private(set) var motionStatus: HeadphoneMotionService.Status = .looking
    @Published private(set) var message = "Connect your AirPods and face your Mac."
    @Published var guardEnabled = true {
        didSet { guardEnabledChanged() }
    }
    @Published var microphoneGateEnabled = false {
        didSet { microphoneGateEnabledChanged() }
    }

    private var latestYawRadians: Double?
    private var engine = TurnawayEngine()
    private let motion = HeadphoneMotionService()
    private let microphone = DefaultInputMuteController()

    var canCalibrate: Bool { latestYawRadians != nil }
    var microphoneGateAvailable: Bool { microphone.canMuteDefaultInput() }

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
        switch intentState {
        case .needsCalibration: "waveform.badge.exclamationmark"
        case .listening: "waveform.circle.fill"
        case .turnaway: "waveform.slash"
        }
    }

    init() {
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
        motion.onYaw = { [weak self] yaw in
            self?.ingest(yaw: yaw)
        }
        motion.start()
    }

    func calibrate() {
        guard let latestYawRadians else { return }
        let reading = engine.calibrate(yawRadians: latestYawRadians)
        apply(reading)
        message = "Forward set. The boundary is ready."
    }

    func quit() {
        motion.stop()
        try? microphone.restoreIfNeeded()
        NSApplication.shared.terminate(nil)
    }

    private func ingest(yaw: Double) {
        latestYawRadians = yaw
        objectWillChange.send()
        guard engine.state != .needsCalibration else { return }
        apply(engine.update(yawRadians: yaw, timestamp: ProcessInfo.processInfo.systemUptime))
    }

    private func apply(_ reading: IntentReading) {
        let previousState = intentState
        intentState = guardEnabled ? reading.state : .listening
        relativeYawDegrees = reading.relativeYawDegrees

        guard previousState != intentState else { return }
        synchronizeMicrophoneGate()
    }

    private func guardEnabledChanged() {
        if !guardEnabled {
            intentState = engine.state == .needsCalibration ? .needsCalibration : .listening
            try? microphone.restoreIfNeeded()
        } else if engine.state != .needsCalibration {
            intentState = engine.state
            synchronizeMicrophoneGate()
        }
    }

    private func microphoneGateEnabledChanged() {
        if microphoneGateEnabled {
            synchronizeMicrophoneGate()
        } else {
            try? microphone.restoreIfNeeded()
        }
    }

    private func synchronizeMicrophoneGate() {
        guard microphoneGateEnabled else { return }

        do {
            if guardEnabled && intentState == .turnaway {
                try microphone.muteForTurnaway()
            } else {
                try microphone.restoreIfNeeded()
            }
        } catch {
            microphoneGateEnabled = false
            message = error.localizedDescription
        }
    }
}
