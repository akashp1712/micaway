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
    private var latestYawUptime: TimeInterval?
    private var lastPublishedMotionLive = false
    private var muteWatchdog: Timer?
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
    /// Written by earlier versions after seeding six call apps onto
    /// Never mute during. Read only to recognise those installs.
    private static let didSeedProtectedApplicationsDefaultsKey = "didSeedProtectedApplications"
    /// Set once the current seed or the legacy-seed migration has run.
    private static let didApplyApplicationListDefaultsKey = "didApplyCallApplicationDefaults"

    var canCalibrate: Bool { latestYawRadians != nil }

    /// AirPods are connected and head-motion samples are still arriving.
    var motionLive: Bool {
        MuteResolver.motionIsLive(
            connected: motionStatus == .connected,
            secondsSinceLastSample: latestYawUptime.map {
                ProcessInfo.processInfo.systemUptime - $0
            }
        )
    }
    var activeApplicationAllowed: Bool {
        // An app on Never mute during wins in every scope mode.
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

    var statusCopy: MenuStatusCopy {
        let selectedIdentifiers = Set(selectedApplications.map(\.bundleIdentifier))
        return MenuStatusCopy.resolve(
            turnawayEnabled: turnawayEnabled,
            motionProblem: motionProblem,
            motionConnected: motionStatus == .connected,
            motionLive: motionLive,
            intentState: intentState,
            automaticMutingAllowed: activeApplicationAllowed,
            protectedNamesOnMic: activeProtectedApplications.map(\.name),
            activeInputNames: audioInputSnapshot.applications.map(\.name),
            selectedAppOnMic: applicationScope == .selectedApps
                && audioInputSnapshot.applications.contains {
                    selectedIdentifiers.contains($0.bundleIdentifier)
                },
            hasUnidentifiedInput: audioInputSnapshot.hasUnidentifiedApplication
        )
    }

    private var motionProblem: String? {
        if case let .unavailable(reason) = motionStatus { return reason }
        return nil
    }

    var statusTitle: String { statusCopy.title }
    var statusDetail: String { statusCopy.detail }

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
        applicationScope: ApplicationScope = .selectedApps
    ) {
        self.turnawayEnabled = turnawayEnabled
        self.turnAngleDegrees = SensitivityLimits.defaultDegrees
        self.engine = TurnawayEngine(
            configuration: .forTurnAngle(enterThresholdDegrees: SensitivityLimits.defaultDegrees)
        )
        self.applicationScope = applicationScope
        self.selectedApplications = ApplicationListDefaults.allowedApplications
        self.protectedApplications = ApplicationListDefaults.protectedApplications
        self.audioInputSnapshot = AudioInputSnapshot(
            applications: [ApplicationListDefaults.callApplications[0]]
        )
        self.intentState = snapshotIntent
        self.relativeYawDegrees = yawDegrees
        self.message = message
        self.latestYawRadians = 0
        // Snapshots render over a few seconds; keep motion reading as live.
        self.latestYawUptime = .infinity
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

        let launchState = Self.loadApplicationLists()
        applicationScope = launchState.scope
        selectedApplications = launchState.lists.allowed
        protectedApplications = launchState.lists.protected

        motion.onStatus = { [weak self] status in
            guard let self else { return }
            motionStatus = status
            switch status {
            case .looking:
                message = "Put in your AirPods to begin."
            case .connected:
                message = "Motion connected. Face your Mac and calibrate."
            case let .unavailable(reason):
                message = reason
            }
            // Losing motion must release a turnaway mute right away.
            applyMuteState()
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
        startMuteWatchdog()
        // Restores inputs a previous run muted but never got to unmute
        // (crash, forced quit, or a device that was absent at the time).
        applyMuteState()
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
        let wasLive = motionLive
        latestYawRadians = yaw
        latestYawUptime = ProcessInfo.processInfo.systemUptime
        if motionLive != lastPublishedMotionLive {
            lastPublishedMotionLive = motionLive
        }
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
        } else {
            apply(engine.update(yawRadians: yaw, timestamp: ProcessInfo.processInfo.systemUptime))
        }

        // apply() mutes only when the intent state changes. Samples can resume
        // while the wearer is still turned away; without this the menu would
        // say "Muted" and the mic would stay open until the next turn.
        if !wasLive && motionLive {
            applyMuteState()
        }
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

    private var shouldMuteNow: Bool {
        MuteResolver.shouldMute(
            turnawayEnabled: turnawayEnabled,
            microphoneInUse: !audioInputSnapshot.applications.isEmpty
                || audioInputSnapshot.hasUnidentifiedApplication,
            applicationAllowed: activeApplicationAllowed,
            motionLive: motionLive,
            intentState: intentState
        )
    }

    private func applyMuteState() {
        let shouldMute = shouldMuteNow
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

    /// Motion samples can simply stop (no disconnect callback) when a call
    /// switches the AirPods' Bluetooth profile, and a muted input can vanish
    /// and come back under a new ID. Neither produces an event, so poll: while
    /// MicAway holds a mute it no longer should, keep releasing it.
    private func startMuteWatchdog() {
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkMuteWatchdog() }
        }
        RunLoop.main.add(timer, forMode: .common)
        muteWatchdog = timer
    }

    private func checkMuteWatchdog() {
        let live = motionLive
        if live != lastPublishedMotionLive {
            lastPublishedMotionLive = live
            objectWillChange.send()
        }
        // Release a mute that is no longer justified, and re-assert one that
        // should still be held. Re-assert covers an input that AirPods re-add
        // under a new ID without its mute, which produces no other event.
        if shouldMuteNow || microphone.holdsMutes {
            applyMuteState()
        }
    }

    func prepareForTermination() {
        muteWatchdog?.invalidate()
        muteWatchdog = nil
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
        Self.persist(selectedApplications, forKey: Self.selectedApplicationsDefaultsKey)
    }

    private func persistProtectedApplications() {
        Self.persist(protectedApplications, forKey: Self.protectedApplicationsDefaultsKey)
    }

    private static func persist(_ applications: [ScopedApplication], forKey key: String) {
        guard let data = try? JSONEncoder().encode(applications) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func loadApplications(forKey key: String) -> [ScopedApplication]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([ScopedApplication].self, from: data)
    }

    /// Resolves Allowed apps, Never mute during, and Use in for this launch,
    /// applying the first-launch seed or the one-time legacy migration (see
    /// `ApplicationListDefaults.resolve`) and persisting the result.
    ///
    /// Fresh installs default Use in to Selected apps. Existing installs that
    /// never chose a scope ran as Every app, so that is pinned rather than
    /// silently switching them to Selected apps.
    private static func loadApplicationLists() -> (
        lists: ApplicationListDefaults.Lists,
        scope: ApplicationScope
    ) {
        let defaults = UserDefaults.standard
        let storedAllowed = loadApplications(forKey: selectedApplicationsDefaultsKey)
        let storedProtected = loadApplications(forKey: protectedApplicationsDefaultsKey)
        let didSeedLegacyDefaults = defaults.bool(forKey: didSeedProtectedApplicationsDefaultsKey)
        let didApplyCurrentDefaults = defaults.bool(forKey: didApplyApplicationListDefaultsKey)

        let lists = ApplicationListDefaults.resolve(
            storedAllowed: storedAllowed,
            storedProtected: storedProtected,
            didSeedLegacyDefaults: didSeedLegacyDefaults,
            didApplyCurrentDefaults: didApplyCurrentDefaults
        )

        var scope = defaults.string(forKey: applicationScopeDefaultsKey)
            .flatMap(ApplicationScope.init(rawValue:))
        if !didApplyCurrentDefaults {
            persist(lists.allowed, forKey: selectedApplicationsDefaultsKey)
            persist(lists.protected, forKey: protectedApplicationsDefaultsKey)
            defaults.set(true, forKey: didApplyApplicationListDefaultsKey)
            if scope == nil {
                let isExistingInstall = storedAllowed != nil
                    || storedProtected != nil
                    || didSeedLegacyDefaults
                scope = isExistingInstall ? .everyApp : .selectedApps
                defaults.set(scope?.rawValue, forKey: applicationScopeDefaultsKey)
            }
        }
        return (lists, scope ?? .selectedApps)
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
