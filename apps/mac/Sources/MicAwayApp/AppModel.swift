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
    @Published var turnawayEnabled: Bool {
        didSet {
            guard turnawayEnabled != oldValue else { return }
            UserDefaults.standard.set(turnawayEnabled, forKey: Self.turnawayEnabledDefaultsKey)
            turnawayEnabledChanged()
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
    @Published var applicationScope: ApplicationScope {
        didSet {
            guard applicationScope != oldValue else { return }
            UserDefaults.standard.set(applicationScope.rawValue, forKey: Self.applicationScopeDefaultsKey)
            applyMuteState()
        }
    }
    @Published private(set) var activeApplication: ScopedApplication?
    @Published private(set) var selectedApplications: [ScopedApplication]
    @Published private(set) var audioInputSnapshot = AudioInputSnapshot()

    private var latestYawRadians: Double?
    private var engine = TurnawayEngine()
    private let motion = HeadphoneMotionService()
    private let microphone = InputMuteController()
    private let audioInputMonitor = AudioInputApplicationMonitor()
    private var workspaceActivationObserver: NSObjectProtocol?
    private static let legacyMicrophoneGateDefaultsKey = "microphoneGateEnabled"
    private static let sensitivityDefaultsKey = "sensitivity"
    private static let turnawayEnabledDefaultsKey = "turnawayEnabled"
    private static let applicationScopeDefaultsKey = "applicationScope"
    private static let selectedApplicationsDefaultsKey = "selectedApplications"

    var canCalibrate: Bool { latestYawRadians != nil }
    var activeApplicationAllowed: Bool {
        return switch applicationScope {
        case .everyApp:
            true
        case .selectedApps:
            selectedModeAllowsAutomaticMuting
        }
    }

    var activeApplicationSelected: Bool {
        activeApplication.map { activeApplication in
            selectedApplications.contains {
                $0.bundleIdentifier == activeApplication.bundleIdentifier
            }
        } ?? false
    }

    var activeApplicationName: String {
        activeApplication?.name ?? "the current app"
    }

    var statusTitle: String {
        if !turnawayEnabled { return "Paused" }
        if !activeApplicationAllowed { return "Inactive here" }
        return switch intentState {
        case .needsCalibration: "Face your Mac"
        case .listening: "Listening"
        case .turnaway: "Not for your Mac"
        }
    }

    var statusDetail: String {
        if !turnawayEnabled {
            return "Turnaway muting is off. Your other mic controls are unchanged."
        }
        if !activeApplicationAllowed {
            if audioInputSnapshot.hasUnidentifiedApplication {
                return "MicAway could not identify the voice app, so it stays safely inactive."
            }
            if audioInputSnapshot.applications.isEmpty {
                return "Waiting for a selected app to use the microphone."
            }
            let names = audioInputSnapshot.applications.map(\.name).joined(separator: ", ")
            return "Automatic muting is off while \(names) uses the microphone."
        }
        return switch intentState {
        case .needsCalibration:
            "Calibrate once while looking forward."
        case .listening:
            "Turn away to pause voice input."
        case .turnaway:
            "Your side conversation stays out."
        }
    }

    var menuBarSymbol: String {
        if !turnawayEnabled { return "pause.circle.fill" }
        if !activeApplicationAllowed { return "waveform.circle" }
        return switch intentState {
        case .needsCalibration: "waveform.badge.exclamationmark"
        case .listening: "waveform.circle.fill"
        case .turnaway: "waveform.slash"
        }
    }

    init() {
        turnawayEnabled = UserDefaults.standard.object(
            forKey: Self.turnawayEnabledDefaultsKey
        ) as? Bool ?? UserDefaults.standard.object(
            forKey: Self.legacyMicrophoneGateDefaultsKey
        ) as? Bool ?? true

        let storedSensitivity = UserDefaults.standard.string(
            forKey: Self.sensitivityDefaultsKey
        ).flatMap(Sensitivity.init(rawValue:)) ?? .default
        sensitivity = storedSensitivity
        engine = TurnawayEngine(configuration: storedSensitivity.configuration)

        applicationScope = UserDefaults.standard.string(
            forKey: Self.applicationScopeDefaultsKey
        ).flatMap(ApplicationScope.init(rawValue:)) ?? .everyApp
        selectedApplications = Self.loadSelectedApplications()

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
        audioInputMonitor.onChange = { [weak self] snapshot in
            guard let self else { return }
            audioInputSnapshot = snapshot
            applyMuteState()
        }
        observeActiveApplication()
        audioInputMonitor.start()
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

    func setActiveApplicationAllowed(_ allowed: Bool) {
        guard let activeApplication else { return }
        selectedApplications.removeAll {
            $0.bundleIdentifier == activeApplication.bundleIdentifier
        }
        if allowed {
            selectedApplications.append(activeApplication)
            selectedApplications.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
        persistSelectedApplications()
        objectWillChange.send()
        applyMuteState()
    }

    func removeSelectedApplication(_ application: ScopedApplication) {
        selectedApplications.removeAll { $0.bundleIdentifier == application.bundleIdentifier }
        persistSelectedApplications()
        objectWillChange.send()
        applyMuteState()
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
        intentState = reading.state
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

    private func turnawayEnabledChanged() {
        if turnawayEnabled, let latestYawRadians, engine.state != .needsCalibration {
            apply(engine.reanchor(yawRadians: latestYawRadians))
            message = "Resumed and re-centered to your current position."
        }
        applyMuteState()
    }

    private func applyMuteState() {
        let shouldMute = MuteResolver.shouldMute(
            turnawayEnabled: turnawayEnabled,
            applicationAllowed: activeApplicationAllowed,
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
        }
    }

    func prepareForTermination() {
        audioInputMonitor.stop()
        motion.stop()
        try? microphone.restoreIfNeeded()
    }

    private func observeActiveApplication() {
        updateActiveApplication(NSWorkspace.shared.frontmostApplication)
        workspaceActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication else { return }
            Task { @MainActor in
                self?.updateActiveApplication(application)
            }
        }
    }

    private func updateActiveApplication(_ application: NSRunningApplication?) {
        guard let application,
              application.bundleIdentifier != Bundle.main.bundleIdentifier,
              let bundleIdentifier = application.bundleIdentifier,
              let name = application.localizedName,
              !name.isEmpty else { return }

        let updated = ScopedApplication(bundleIdentifier: bundleIdentifier, name: name)
        guard updated != activeApplication else { return }
        activeApplication = updated
        applyMuteState()
    }

    private func persistSelectedApplications() {
        guard let data = try? JSONEncoder().encode(selectedApplications) else { return }
        UserDefaults.standard.set(data, forKey: Self.selectedApplicationsDefaultsKey)
    }

    private static func loadSelectedApplications() -> [ScopedApplication] {
        guard let data = UserDefaults.standard.data(forKey: selectedApplicationsDefaultsKey),
              let applications = try? JSONDecoder().decode([ScopedApplication].self, from: data)
        else { return [] }
        return applications
    }

    private var selectedModeAllowsAutomaticMuting: Bool {
        ApplicationScopePolicy.allowsAutomaticMuting(
            selectedBundleIdentifiers: Set(selectedApplications.map(\.bundleIdentifier)),
            activeInputBundleIdentifiers: Set(
                audioInputSnapshot.applications.map(\.bundleIdentifier)
            ),
            hasUnidentifiedInputApplication: audioInputSnapshot.hasUnidentifiedApplication
        )
    }
}
