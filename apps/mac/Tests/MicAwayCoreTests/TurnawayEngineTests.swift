import Testing
@testable import MicAwayCore

struct TurnawayEngineTests {
    @Test func requiresCalibration() {
        var engine = TurnawayEngine()
        let reading = engine.update(yawRadians: 0.4, timestamp: 0)
        #expect(reading.state == .needsCalibration)
    }

    // Default engine == Medium sensitivity: enter 45°, exit 28°,
    // enter dwell 0.40s, exit dwell 0.34s.
    @Test func dwellAndHysteresis() {
        var engine = TurnawayEngine()
        engine.calibrate(yawRadians: 0)

        #expect(engine.update(yawRadians: degrees(50), timestamp: 0).state == .listening)
        #expect(engine.update(yawRadians: degrees(50), timestamp: 0.45).state == .turnaway)

        #expect(engine.update(yawRadians: degrees(30), timestamp: 0.5).state == .turnaway)
        #expect(engine.update(yawRadians: degrees(20), timestamp: 0.6).state == .turnaway)
        #expect(engine.update(yawRadians: degrees(20), timestamp: 1.0).state == .listening)
    }

    @Test func briefGlanceDoesNotTriggerTurnaway() {
        var engine = TurnawayEngine()
        engine.calibrate(yawRadians: 0)

        // Past the enter threshold for a single sample, then back before the dwell.
        #expect(engine.update(yawRadians: degrees(-50), timestamp: 1).state == .listening)
        #expect(engine.update(yawRadians: degrees(-5), timestamp: 1.1).state == .listening)
    }

    @Test func lowSensitivityIgnoresAMediumTurn() {
        var engine = TurnawayEngine(configuration: Sensitivity.low.configuration)
        engine.calibrate(yawRadians: 0)

        // 45° clears Medium's threshold but not Low's 60° — should stay listening.
        #expect(engine.update(yawRadians: degrees(45), timestamp: 0).state == .listening)
        #expect(engine.update(yawRadians: degrees(45), timestamp: 1).state == .listening)
    }

    @Test func highSensitivityCatchesASmallTurn() {
        var engine = TurnawayEngine(configuration: Sensitivity.high.configuration)
        engine.calibrate(yawRadians: 0)

        // 34° clears High's 30° threshold; hold past the 0.24s dwell.
        #expect(engine.update(yawRadians: degrees(34), timestamp: 0).state == .listening)
        #expect(engine.update(yawRadians: degrees(34), timestamp: 0.3).state == .turnaway)
    }

    @Test func referenceFrameJumpWouldFalselyMuteWithoutReanchor() {
        // Documents the bug: CMHeadphoneMotionManager captures a fresh yaw
        // origin each time the motion stream restarts (e.g. AirPods switch
        // Bluetooth profile when a call grabs the mic). Against a stale
        // baseline, the origin jump reads as a turn even though the head is
        // still — so a plain update() mutes.
        var engine = TurnawayEngine()
        engine.calibrate(yawRadians: 0)
        #expect(engine.update(yawRadians: degrees(70), timestamp: 0).state == .listening)
        #expect(engine.update(yawRadians: degrees(70), timestamp: 1).state == .turnaway)
    }

    @Test func reanchorAbsorbsAReferenceFrameJump() {
        // The fix: on a new reference frame, reanchor adopts the current head
        // position as forward and returns to listening, so a 70° origin jump
        // with no real head movement does not mute.
        var engine = TurnawayEngine()
        engine.calibrate(yawRadians: 0)

        let reading = engine.reanchor(yawRadians: degrees(70))
        #expect(reading.state == .listening)
        #expect(abs(reading.relativeYawDegrees) < 0.001)

        // Steady samples in the new frame stay listening — no false mute.
        #expect(engine.update(yawRadians: degrees(72), timestamp: 1).state == .listening)
        #expect(engine.update(yawRadians: degrees(72), timestamp: 2).state == .listening)

        // A genuine turn past the threshold in the new frame still mutes.
        #expect(engine.update(yawRadians: degrees(120), timestamp: 3).state == .listening)
        #expect(engine.update(yawRadians: degrees(120), timestamp: 4).state == .turnaway)
    }

    @Test func reanchorBeforeCalibrationStaysUncalibrated() {
        // A stream (re)start before the user has ever calibrated must not
        // silently set a forward direction.
        var engine = TurnawayEngine()
        let reading = engine.reanchor(yawRadians: degrees(30))
        #expect(reading.state == .needsCalibration)
        #expect(engine.baselineYawRadians == nil)
    }

    @Test func angleWrapNearPi() {
        var engine = TurnawayEngine()
        engine.calibrate(yawRadians: degrees(179))

        let reading = engine.update(yawRadians: degrees(-179), timestamp: 0)
        #expect(abs(reading.relativeYawDegrees - 2) < 0.001)
        #expect(reading.state == .listening)
    }
}

private func degrees(_ value: Double) -> Double {
    value * .pi / 180
}
