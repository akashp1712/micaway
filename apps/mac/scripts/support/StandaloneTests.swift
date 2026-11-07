import Foundation
import MicAwayCore

// A toolchain-independent mirror of the canonical swift-testing suite in
// Tests/MicAwayCoreTests. Each check corresponds 1:1 to an @Test/#expect
// there, so `test.sh` verifies the same behaviour even when `swift test`
// itself is unavailable (e.g. a Command Line Tools install whose
// PackageDescription library is missing the Package symbols). Keep this file
// in lock-step with the swift-testing tests: a change in one belongs in both.

var failures = 0

func check(_ condition: Bool, _ label: String) {
    if condition {
        print("ok   - \(label)")
    } else {
        failures += 1
        print("FAIL - \(label)")
    }
}

func degrees(_ value: Double) -> Double { value * .pi / 180 }

// MARK: - TurnawayEngineTests

// requiresCalibration
do {
    var engine = TurnawayEngine()
    let reading = engine.update(yawRadians: 0.4, timestamp: 0)
    check(reading.state == .needsCalibration, "engine requires calibration first")
}

// dwellAndHysteresis — default engine == Medium: enter 45°, exit 28°,
// enter dwell 0.40s, exit dwell 0.34s.
do {
    var engine = TurnawayEngine()
    engine.calibrate(yawRadians: 0)
    check(engine.update(yawRadians: degrees(50), timestamp: 0).state == .listening,
          "engine stays listening before enter dwell")
    check(engine.update(yawRadians: degrees(50), timestamp: 0.45).state == .turnaway,
          "engine enters turnaway after enter dwell")
    check(engine.update(yawRadians: degrees(30), timestamp: 0.5).state == .turnaway,
          "engine stays turnaway while still past exit threshold")
    check(engine.update(yawRadians: degrees(20), timestamp: 0.6).state == .turnaway,
          "engine stays turnaway before exit dwell elapses")
    check(engine.update(yawRadians: degrees(20), timestamp: 1.0).state == .listening,
          "engine exits turnaway after exit dwell")
}

// briefGlanceDoesNotTriggerTurnaway
do {
    var engine = TurnawayEngine()
    engine.calibrate(yawRadians: 0)
    check(engine.update(yawRadians: degrees(-50), timestamp: 1).state == .listening,
          "single sample past threshold stays listening")
    check(engine.update(yawRadians: degrees(-5), timestamp: 1.1).state == .listening,
          "glance back before dwell stays listening")
}

// lowSensitivityIgnoresAMediumTurn — 45° clears Medium but not Low's 60°.
do {
    var engine = TurnawayEngine(configuration: Sensitivity.low.configuration)
    engine.calibrate(yawRadians: 0)
    check(engine.update(yawRadians: degrees(45), timestamp: 0).state == .listening,
          "low sensitivity: 45° stays listening at t0")
    check(engine.update(yawRadians: degrees(45), timestamp: 1).state == .listening,
          "low sensitivity: 45° still listening after dwell window")
}

// highSensitivityCatchesASmallTurn — 34° clears High's 30° after 0.24s dwell.
do {
    var engine = TurnawayEngine(configuration: Sensitivity.high.configuration)
    engine.calibrate(yawRadians: 0)
    check(engine.update(yawRadians: degrees(34), timestamp: 0).state == .listening,
          "high sensitivity: 34° listening before dwell")
    check(engine.update(yawRadians: degrees(34), timestamp: 0.3).state == .turnaway,
          "high sensitivity: 34° mutes after dwell")
}

// referenceFrameJumpWouldFalselyMuteWithoutReanchor — documents the bug.
do {
    var engine = TurnawayEngine()
    engine.calibrate(yawRadians: 0)
    check(engine.update(yawRadians: degrees(70), timestamp: 0).state == .listening,
          "frame jump: listening before dwell")
    check(engine.update(yawRadians: degrees(70), timestamp: 1).state == .turnaway,
          "frame jump against stale baseline falsely mutes (bug)")
}

// reanchorAbsorbsAReferenceFrameJump — the fix.
do {
    var engine = TurnawayEngine()
    engine.calibrate(yawRadians: 0)
    let reading = engine.reanchor(yawRadians: degrees(70))
    check(reading.state == .listening, "reanchor returns to listening")
    check(abs(reading.relativeYawDegrees) < 0.001, "reanchor zeroes the relative angle")
    check(engine.update(yawRadians: degrees(72), timestamp: 1).state == .listening,
          "reanchor: steady head in new frame stays listening")
    check(engine.update(yawRadians: degrees(72), timestamp: 2).state == .listening,
          "reanchor: still listening after dwell window")
    check(engine.update(yawRadians: degrees(120), timestamp: 3).state == .listening,
          "reanchor: genuine turn listening before dwell")
    check(engine.update(yawRadians: degrees(120), timestamp: 4).state == .turnaway,
          "reanchor: genuine turn still mutes in the new frame")
}

// reanchorBeforeCalibrationStaysUncalibrated.
do {
    var engine = TurnawayEngine()
    let reading = engine.reanchor(yawRadians: degrees(30))
    check(reading.state == .needsCalibration, "reanchor before calibration stays uncalibrated")
    check(engine.baselineYawRadians == nil, "reanchor before calibration sets no baseline")
}

// angleWrapNearPi
do {
    var engine = TurnawayEngine()
    engine.calibrate(yawRadians: degrees(179))
    let reading = engine.update(yawRadians: degrees(-179), timestamp: 0)
    check(abs(reading.relativeYawDegrees - 2) < 0.001,
          "angle wrap near ±π yields a 2° relative turn")
    check(reading.state == .listening, "2° wrap-around stays listening")
}

// MARK: - SensitivityTests

// defaultIsMedium
check(Sensitivity.default == .medium, "default sensitivity is medium")

// mediumMatchesEngineDefaults
check(Sensitivity.medium.configuration == TurnawayConfiguration(),
      "medium sensitivity matches engine defaults")

// lowerSensitivityNeedsABiggerTurn — enter threshold grows high < medium < low.
check(Sensitivity.high.configuration.enterThresholdDegrees
        < Sensitivity.medium.configuration.enterThresholdDegrees,
      "high enter threshold is smaller than medium")
check(Sensitivity.medium.configuration.enterThresholdDegrees
        < Sensitivity.low.configuration.enterThresholdDegrees,
      "medium enter threshold is smaller than low")

// everyPresetKeepsHysteresis — enter must stay above exit.
for sensitivity in Sensitivity.allCases {
    let config = sensitivity.configuration
    check(config.enterThresholdDegrees > config.exitThresholdDegrees,
          "\(sensitivity.rawValue) keeps enter > exit hysteresis")
}

// presetOrderIsLowToHigh
check(Sensitivity.allCases == [.low, .medium, .high],
      "preset order is low, medium, high")

// forTurnAngleUsesTheGivenEnterThreshold
do {
    let config = TurnawayConfiguration.forTurnAngle(enterThresholdDegrees: 45)
    check(config.enterThresholdDegrees == 45, "forTurnAngle keeps the enter threshold")
    check(config.exitThresholdDegrees == 28, "forTurnAngle scales exit to round(enter * 0.62)")
}

// forTurnAngleClampsToLimits
check(TurnawayConfiguration.forTurnAngle(enterThresholdDegrees: 5)
        .enterThresholdDegrees == SensitivityLimits.minDegrees,
      "forTurnAngle clamps below the minimum")
check(TurnawayConfiguration.forTurnAngle(enterThresholdDegrees: 120)
        .enterThresholdDegrees == SensitivityLimits.maxDegrees,
      "forTurnAngle clamps above the maximum")

// forTurnAngleKeepsHysteresisAcrossTheRange
do {
    var keepsHysteresis = true
    for degrees in stride(from: SensitivityLimits.minDegrees,
                          through: SensitivityLimits.maxDegrees,
                          by: 1) {
        let config = TurnawayConfiguration.forTurnAngle(enterThresholdDegrees: degrees)
        if config.enterThresholdDegrees <= config.exitThresholdDegrees {
            keepsHysteresis = false
        }
    }
    check(keepsHysteresis, "forTurnAngle keeps enter > exit across the range")
}

// forTurnAngleGivesBiggerTurnsALongerDwell
do {
    let sensitive = TurnawayConfiguration.forTurnAngle(
        enterThresholdDegrees: SensitivityLimits.minDegrees
    )
    let deliberate = TurnawayConfiguration.forTurnAngle(
        enterThresholdDegrees: SensitivityLimits.maxDegrees
    )
    check(sensitive.enterDwellSeconds < deliberate.enterDwellSeconds,
          "forTurnAngle gives bigger turns a longer enter dwell")
    check(deliberate.exitThresholdDegrees > sensitive.exitThresholdDegrees,
          "forTurnAngle exit threshold grows with the turn angle")
}

// MARK: - MuteResolverTests

check(MuteResolver.shouldMute(turnawayEnabled: true,
                              microphoneInUse: true,
                              applicationAllowed: true,
                              motionLive: true,
                              intentState: .turnaway),
      "turnaway mutes when enabled in an allowed app")
check(!MuteResolver.shouldMute(turnawayEnabled: true,
                               microphoneInUse: true,
                               applicationAllowed: true,
                               motionLive: true,
                               intentState: .listening),
      "listening does not mute")
check(!MuteResolver.shouldMute(turnawayEnabled: false,
                               microphoneInUse: true,
                               applicationAllowed: true,
                               motionLive: true,
                               intentState: .turnaway),
      "pause suppresses automatic motion mute")
check(!MuteResolver.shouldMute(turnawayEnabled: true,
                               microphoneInUse: true,
                               applicationAllowed: false,
                               motionLive: true,
                               intentState: .turnaway),
      "blocked application suppresses motion mute")
check(!MuteResolver.shouldMute(turnawayEnabled: true,
                               microphoneInUse: true,
                               applicationAllowed: true,
                               motionLive: false,
                               intentState: .turnaway),
      "lost motion releases a turnaway mute")
check(!MuteResolver.shouldMute(turnawayEnabled: true,
                               microphoneInUse: false,
                               applicationAllowed: true,
                               motionLive: true,
                               intentState: .turnaway),
      "idle mic is never muted")
check(MuteResolver.motionIsLive(connected: true, secondsSinceLastSample: 0.2)
        && !MuteResolver.motionIsLive(connected: true, secondsSinceLastSample: 5)
        && !MuteResolver.motionIsLive(connected: true, secondsSinceLastSample: nil)
        && !MuteResolver.motionIsLive(connected: false, secondsSinceLastSample: 0.2),
      "motion is live only when connected with fresh samples")

// MARK: - MutedInputLedgerTests

do {
    // restoreFindsARecreatedDeviceByUID
    var ledger = MutedInputLedger()
    ledger.recordMuted("airpods-uid")
    check(ledger.restorable(presentDeviceUIDs: ["airpods-uid", "builtin"]) == ["airpods-uid"],
          "restore finds a recreated device by UID")

    // absentDeviceStaysPendingUntilItReturns
    var pending = MutedInputLedger()
    pending.recordMuted("airpods-uid")
    check(pending.restorable(presentDeviceUIDs: ["builtin"]).isEmpty && !pending.isEmpty,
          "absent device stays pending until it returns")

    // restoredDeviceLeavesTheLedger
    var restored = MutedInputLedger()
    restored.recordMuted("airpods-uid")
    restored.recordRestored("airpods-uid")
    check(restored.isEmpty, "restored device leaves the ledger")

    // ledgerRestoresOnlyWhatItMuted
    var mine = MutedInputLedger()
    mine.recordMuted("builtin")
    check(mine.restorable(presentDeviceUIDs: ["builtin", "user-muted-usb"]) == ["builtin"],
          "ledger restores only what it muted")

    // ledgerSurvivesARelaunch
    check(MutedInputLedger(deviceUIDs: mine.deviceUIDs) == mine,
          "ledger survives a relaunch")
}

// MARK: - ApplicationScopePolicyTests

check(ApplicationScopePolicy.allowsAutomaticMuting(
        selectedBundleIdentifiers: ["org.example.dictation"],
        activeInputBundleIdentifiers: ["org.example.dictation"],
        hasUnidentifiedInputApplication: false),
      "selected voice app allows automatic muting")
check(!ApplicationScopePolicy.allowsAutomaticMuting(
        selectedBundleIdentifiers: ["org.example.dictation"],
        activeInputBundleIdentifiers: ["org.example.dictation", "org.example.meeting"],
        hasUnidentifiedInputApplication: false),
      "meeting app vetoes automatic muting")
check(!ApplicationScopePolicy.allowsAutomaticMuting(
        selectedBundleIdentifiers: ["org.example.dictation"],
        activeInputBundleIdentifiers: [],
        hasUnidentifiedInputApplication: false),
      "no active input does not mute")
check(!ApplicationScopePolicy.allowsAutomaticMuting(
        selectedBundleIdentifiers: ["org.example.dictation"],
        activeInputBundleIdentifiers: ["org.example.dictation"],
        hasUnidentifiedInputApplication: true),
      "unidentified input fails open")

// MARK: - ProtectedApplicationPolicyTests

check(ProtectedApplicationPolicy.blocksMuting(
        protectedBundleIdentifiers: ["us.zoom.xos"],
        activeInputBundleIdentifiers: ["us.zoom.xos"]),
      "protected app on mic blocks muting")
check(ProtectedApplicationPolicy.blocksMuting(
        protectedBundleIdentifiers: ["us.zoom.xos"],
        activeInputBundleIdentifiers: ["org.example.dictation", "us.zoom.xos"]),
      "protected app alongside dictation blocks muting")
check(!ProtectedApplicationPolicy.blocksMuting(
        protectedBundleIdentifiers: ["us.zoom.xos"],
        activeInputBundleIdentifiers: ["org.example.dictation"]),
      "unprotected input does not block muting")
check(!ProtectedApplicationPolicy.blocksMuting(
        protectedBundleIdentifiers: ["us.zoom.xos"],
        activeInputBundleIdentifiers: []),
      "no active input does not block muting")
check(!ProtectedApplicationPolicy.blocksMuting(
        protectedBundleIdentifiers: [],
        activeInputBundleIdentifiers: ["us.zoom.xos"]),
      "empty protected list does not block muting")

// MARK: - ApplicationListDefaultsTests

do {
    let zoom = ScopedApplication(bundleIdentifier: "us.zoom.xos", name: "Zoom")
    let chrome = ScopedApplication(bundleIdentifier: "com.google.Chrome", name: "Google Chrome")
    let legacySix = ApplicationListDefaults.callApplications

    // freshInstallAllowsCallAppsAndBrowsersAndProtectsNothing
    let fresh = ApplicationListDefaults.resolve(
        storedAllowed: nil, storedProtected: nil,
        didSeedLegacyDefaults: false, didApplyCurrentDefaults: false)
    check(fresh.protected.isEmpty, "fresh install: Never mute during is empty")
    let freshAllowed = Set(fresh.allowed.map(\.bundleIdentifier))
    check(freshAllowed.isSuperset(of: [
        "us.zoom.xos", "com.microsoft.teams2", "com.tinyspeck.slackmacgap",
        "com.apple.FaceTime", "com.hnc.Discord", "com.cisco.webexmeetingsapp",
        "com.google.Chrome", "com.apple.Safari", "company.thebrowser.Browser",
        "org.mozilla.firefox",
    ]), "fresh install: Allowed has call apps and browsers")

    // untouchedLegacySeedMovesIntoAllowed
    let migrated = ApplicationListDefaults.resolve(
        storedAllowed: [], storedProtected: legacySix.reversed(),
        didSeedLegacyDefaults: true, didApplyCurrentDefaults: false)
    check(Set(migrated.allowed) == Set(legacySix) && migrated.allowed.count == 6,
          "migration: legacy six move into Allowed")
    check(migrated.protected.isEmpty, "migration: Never mute during cleared")

    // editedNeverMuteListIsNotOverwritten
    let edited = legacySix.filter { $0 != zoom } + [chrome]
    let keptProtected = ApplicationListDefaults.resolve(
        storedAllowed: [], storedProtected: edited,
        didSeedLegacyDefaults: true, didApplyCurrentDefaults: false)
    check(keptProtected.protected == edited && keptProtected.allowed.isEmpty,
          "migration: edited Never mute during is not overwritten")

    // editedAllowedListIsNotOverwritten
    let keptAllowed = ApplicationListDefaults.resolve(
        storedAllowed: [chrome], storedProtected: legacySix,
        didSeedLegacyDefaults: true, didApplyCurrentDefaults: false)
    check(keptAllowed.allowed == [chrome] && keptAllowed.protected == legacySix,
          "migration: edited Allowed apps is not overwritten")

    // migrationRunsOnlyOnce
    let once = ApplicationListDefaults.resolve(
        storedAllowed: [], storedProtected: legacySix,
        didSeedLegacyDefaults: true, didApplyCurrentDefaults: true)
    check(once.allowed.isEmpty && once.protected == legacySix,
          "migration runs only once")

    // freshSeedLetsZoomMute
    check(!ProtectedApplicationPolicy.blocksMuting(
            protectedBundleIdentifiers: Set(fresh.protected.map(\.bundleIdentifier)),
            activeInputBundleIdentifiers: ["us.zoom.xos"])
          && ApplicationScopePolicy.allowsAutomaticMuting(
            selectedBundleIdentifiers: freshAllowed,
            activeInputBundleIdentifiers: ["us.zoom.xos"],
            hasUnidentifiedInputApplication: false),
          "fresh seed lets Zoom mute")
}

// MARK: - MenuStatusCopyTests

do {
    func copy(
        intentState: IntentState = .listening,
        motionConnected: Bool = true,
        motionLive: Bool? = nil,
        allowed: Bool = true,
        protectedNames: [String] = [],
        inputNames: [String] = ["Zoom"],
        selectedAppOnMic: Bool = true,
        motionProblem: String? = nil
    ) -> MenuStatusCopy {
        MenuStatusCopy.resolve(
            turnawayEnabled: true, motionProblem: motionProblem,
            motionConnected: motionConnected,
            motionLive: motionLive ?? motionConnected,
            intentState: intentState, automaticMutingAllowed: allowed,
            protectedNamesOnMic: protectedNames, activeInputNames: inputNames,
            selectedAppOnMic: selectedAppOnMic, hasUnidentifiedInput: false)
    }

    let onCall = copy()
    check(onCall.title == "On for this call" && onCall.detail == "Live — you’re facing the Mac.",
          "selected Zoom on mic is On for this call, not Inactive here")
    check(copy(intentState: .turnaway).detail == "Muted — you’re turned away.",
          "turned away in selected Zoom says Muted")
    let idle = copy(allowed: false, inputNames: [], selectedAppOnMic: false)
    check(idle.title == "Inactive here"
            && idle.detail == "Waiting for a selected app to use the microphone.",
          "no selected app on mic is Inactive here")
    check(copy(allowed: false, inputNames: ["Zoom", "Recorder"]).title == "Standing by",
          "selected app blocked by another app is not Inactive here")
    let protected = copy(allowed: false, protectedNames: ["FaceTime"])
    check(protected.title == "Standing by" && protected.detail.contains("FaceTime"),
          "Never mute during app on mic stands by")
    check(copy(motionConnected: false).title == "Needs AirPods",
          "selected app without motion asks for AirPods")
    let noMotion = copy(inputNames: [], motionProblem: "Turn on Motion access.")
    check(noMotion.title == "No head motion" && noMotion.detail == "Turn on Motion access.",
          "motion problem is shown even when idle")
    let stalled = copy(intentState: .turnaway, motionLive: false)
    check(stalled.title == "Motion paused" && !stalled.detail.contains("Muted"),
          "stalled motion says the mic stays open")
}

if failures == 0 {
    print("ALL PASS")
    exit(0)
} else {
    print("\(failures) FAILURE(S)")
    exit(1)
}
