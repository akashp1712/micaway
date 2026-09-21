import AppKit
import Combine
import Foundation
import MicAwayCore

enum MenuBarStatus: Equatable {
    case listening
    case turnaway
    case paused
    case inactive
    case needsCalibration
}

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
    /// "Mute past this angle" — the continuous enter threshold in degrees.
    /// Smaller = more sensitive. Bounded by `SensitivityLimits`.
    @Published var turnAngleDegrees: Double {
        didSet {
            guard turnAngleDegrees != oldValue else { return }
            UserDefaults.standard.set(
                turnAngleDegrees,
                forKey: Self.turnAngleDegreesDefaultsKey
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
    @Published private(set) var protectedApplications: [ScopedApplication]
    @Published private(set) var audioInputSnapshot = AudioInputSnapshot()

    private var latestYawRadians: Double?
    private var engine = TurnawayEngine()
    private let motion = HeadphoneMotionService()
    private let microphone = InputMuteController()
    private let audioInputMonitor = AudioInputApplicationMonitor()
    private var workspaceActivationObserver: NSObjectProtocol?
    private static let legacyMicrophoneGateDefaultsKey = "microphoneGateEnabled"
    private static let sensitivityDefaultsKey = "sensitivity"
    private static let turnAngleDegreesDefaultsKey = "turnAngleDegrees"
    private static let turnawayEnabledDefaultsKey = "turnawayEnabled"
    private static let applicationScopeDefaultsKey = "applicationScope"
    private static let selectedApplicationsDefaultsKey = "selectedApplications"
    private static let protectedApplicationsDefaultsKey = "protectedApplications"
    private static let didSeedProtectedApplicationsDefaultsKey = "didSeedProtectedApplications"

    /// Real-time comms apps that ship pre-protected so meetings work out of the
    /// box. Google Meet is deliberately absent: it runs inside a browser, so
    /// Core Audio reports the browser's bundle ID and protecting it would also
    /// stop a browser-based dictation app from muting. Browser-Meet users add
    /// their browser through "Never mute during → Add …". Bundle IDs are
    /// verified against installed apps during release testing; an ID for an
    /// app that is not installed simply never matches and is harmless.
    private static let defaultProtectedApplications: [ScopedApplication] = [
        ScopedApplication(bundleIdentifier: "us.zoom.xos", name: "Zoom"),
        ScopedApplication(bundleIdentifier: "com.microsoft.teams2", name: "Microsoft Teams"),
        ScopedApplication(bundleIdentifier: "com.cisco.webexmeetingsapp", name: "Webex"),
        ScopedApplication(bundleIdentifier: "com.tinyspeck.slackmacgap", name: "Slack"),
        ScopedApplication(bundleIdentifier: "com.apple.FaceTime", name: "FaceTime"),
        ScopedApplication(bundleIdentifier: "com.hnc.Discord", name: "Discord"),
    ]

    var canCalibrate: Bool { latestYawRadians != nil }
    var activeApplicationAllowed: Bool {
        // A live meeting/call app wins in every scope mode: muting the shared
        // device would flip its mic-off indicator and disturb the call.
        guard !protectedApplicationOnMic else { return false }
        return switch applicationScope {
        case .everyApp:
            true
        case .selectedApps:
            selectedModeAllowsAutomaticMuting
        }
    }

    /// A protected app is currently one of the apps consuming microphone input.
    var protectedApplicationOnMic: Bool {
        ProtectedApplicationPolicy.blocksMuting(
            protectedBundleIdentifiers: Set(protectedApplications.map(\.bundleIdentifier)),
            activeInputBundleIdentifiers: Set(
                audioInputSnapshot.applications.map(\.bundleIdentifier)
            )
        )
    }

    /// The protected apps that are actively on the mic right now, for status copy.
    private var activeProtectedApplications: [ScopedApplication] {
        let protectedIdentifiers = Set(protectedApplications.map(\.bundleIdentifier))
        return audioInputSnapshot.applications.filter {
            protectedIdentifiers.contains($0.bundleIdentifier)
        }
    }

    var activeApplicationProtected: Bool {
        activeApplication.map { activeApplication in
            protectedApplications.contains {
                $0.bundleIdentifier == activeApplication.bundleIdentifier
            }
        } ?? false
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
        if protectedApplicationOnMic { return "Standing by" }
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
        if protectedApplicationOnMic {
            let names = activeProtectedApplications.map(\.name).joined(separator: ", ")
            return "Muting paused so \(names) keeps your microphone."
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

    var menuBarStatus: MenuBarStatus {
        if !turnawayEnabled { return .paused }
        if !activeApplicationAllowed { return .inactive }
        return switch intentState {
        case .needsCalibration: .needsCalibration
        case .listening: .listening
        case .turnaway: .turnaway
        }
    }

    /// Display-only model for marketing screenshots. Does not start motion,
    /// audio monitoring, or persist defaults.
    init(
        snapshotIntent: IntentState,
        yawDegrees: Double,
        turnawayEnabled: Bool = true,
        message: String,
        applicationScope: ApplicationScope = .everyApp
    ) {
        self.turnawayEnabled = turnawayEnabled
        self.turnAngleDegrees = SensitivityLimits.defaultDegrees
        self.engine = TurnawayEngine(
            configuration: .forTurnAngle(enterThresholdDegrees: SensitivityLimits.defaultDegrees)
        )
        self.applicationScope = applicationScope
        self.selectedApplications = []
        self.protectedApplications = []
        self.intentState = snapshotIntent
        self.relativeYawDegrees = yawDegrees
        self.message = message
        self.latestYawRadians = 0
        self.motionStatus = .connected
    }

    init() {
        turnawayEnabled = UserDefaults.standard.object(
            forKey: Self.turnawayEnabledDefaultsKey
        ) as? Bool ?? UserDefaults.standard.object(
            forKey: Self.legacyMicrophoneGateDefaultsKey
        ) as? Bool ?? true

        let storedAngle = Self.loadTurnAngleDegrees()
        turnAngleDegrees = storedAngle
        engine = TurnawayEngine(
            configuration: .forTurnAngle(enterThresholdDegrees: storedAngle)
        )

        applicationScope = UserDefaults.standard.string(
            forKey: Self.applicationScopeDefaultsKey
        ).flatMap(ApplicationScope.init(rawValue:)) ?? .everyApp
        selectedApplications = Self.loadSelectedApplications()
        protectedApplications = Self.loadProtectedApplications()

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

    func setActiveApplicationProtected(_ protectedFlag: Bool) {
        guard let activeApplication else { return }
        protectedApplications.removeAll {
            $0.bundleIdentifier == activeApplication.bundleIdentifier
        }
        if protectedFlag {
            protectedApplications.append(activeApplication)
            protectedApplications.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
        persistProtectedApplications()
        objectWillChange.send()
        applyMuteState()
    }

    func removeProtectedApplication(_ application: ScopedApplication) {
        protectedApplications.removeAll { $0.bundleIdentifier == application.bundleIdentifier }
        persistProtectedApplications()
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
        var rebuilt = TurnawayEngine(
            configuration: .forTurnAngle(enterThresholdDegrees: turnAngleDegrees)
        )
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

    /// Resolves the stored turn angle, migrating the pre-slider Low/Medium/High
    /// enum (persisted under the old "sensitivity" key) to its degree anchor the
    /// first time. New installs and any later launch use the continuous value.
    private static func loadTurnAngleDegrees() -> Double {
        if UserDefaults.standard.object(forKey: turnAngleDegreesDefaultsKey) != nil {
            return SensitivityLimits.clamp(
                UserDefaults.standard.double(forKey: turnAngleDegreesDefaultsKey)
            )
        }
        if let legacy = UserDefaults.standard.string(forKey: sensitivityDefaultsKey)
            .flatMap(Sensitivity.init(rawValue:)) {
            return legacy.configuration.enterThresholdDegrees
        }
        return SensitivityLimits.defaultDegrees
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

    private func persistProtectedApplications() {
        guard let data = try? JSONEncoder().encode(protectedApplications) else { return }
        UserDefaults.standard.set(data, forKey: Self.protectedApplicationsDefaultsKey)
    }

    /// Loads the protected apps, merging in the curated comms defaults exactly
    /// once (first launch). The one-time seed flag means apps the user removes
    /// stay removed rather than reappearing on the next launch.
    private static func loadProtectedApplications() -> [ScopedApplication] {
        var stored: [ScopedApplication] = []
        if let data = UserDefaults.standard.data(forKey: protectedApplicationsDefaultsKey),
           let decoded = try? JSONDecoder().decode([ScopedApplication].self, from: data) {
            stored = decoded
        }

        guard !UserDefaults.standard.bool(forKey: didSeedProtectedApplicationsDefaultsKey) else {
            return stored
        }

        var merged = stored
        let existingIdentifiers = Set(stored.map(\.bundleIdentifier))
        for application in defaultProtectedApplications
        where !existingIdentifiers.contains(application.bundleIdentifier) {
            merged.append(application)
        }
        merged.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        UserDefaults.standard.set(true, forKey: didSeedProtectedApplicationsDefaultsKey)
        if let data = try? JSONEncoder().encode(merged) {
            UserDefaults.standard.set(data, forKey: protectedApplicationsDefaultsKey)
        }
        return merged
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
