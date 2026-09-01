import Testing
@testable import MicAwayCore

struct TurnawayEngineTests {
    @Test func requiresCalibration() {
        var engine = TurnawayEngine()
        let reading = engine.update(yawRadians: 0.4, timestamp: 0)
        #expect(reading.state == .needsCalibration)
    }

    @Test func dwellAndHysteresis() {
        var engine = TurnawayEngine()
        engine.calibrate(yawRadians: 0)

        #expect(engine.update(yawRadians: degrees(32), timestamp: 0).state == .listening)
        #expect(engine.update(yawRadians: degrees(32), timestamp: 0.25).state == .turnaway)

        #expect(engine.update(yawRadians: degrees(22), timestamp: 0.4).state == .turnaway)
        #expect(engine.update(yawRadians: degrees(10), timestamp: 0.5).state == .turnaway)
        #expect(engine.update(yawRadians: degrees(10), timestamp: 0.85).state == .listening)
    }

    @Test func briefGlanceDoesNotTriggerTurnaway() {
        var engine = TurnawayEngine()
        engine.calibrate(yawRadians: 0)

        #expect(engine.update(yawRadians: degrees(-40), timestamp: 1).state == .listening)
        #expect(engine.update(yawRadians: degrees(-5), timestamp: 1.1).state == .listening)
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
