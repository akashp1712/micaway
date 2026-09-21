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
                              applicationAllowed: true,
                              intentState: .turnaway),
      "turnaway mutes when enabled in an allowed app")
check(!MuteResolver.shouldMute(turnawayEnabled: true,
                               applicationAllowed: true,
                               intentState: .listening),
      "listening does not mute")
check(!MuteResolver.shouldMute(turnawayEnabled: false,
                               applicationAllowed: true,
                               intentState: .turnaway),
      "pause suppresses automatic motion mute")
check(!MuteResolver.shouldMute(turnawayEnabled: true,
                               applicationAllowed: false,
                               intentState: .turnaway),
      "blocked application suppresses motion mute")

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

if failures == 0 {
    print("ALL PASS")
    exit(0)
} else {
    print("\(failures) FAILURE(S)")
    exit(1)
}
