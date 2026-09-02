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
