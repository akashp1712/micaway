import XCTest
@testable import HearMeNotCore

final class TurnawayEngineTests: XCTestCase {
    func testRequiresCalibration() {
        var engine = TurnawayEngine()
        let reading = engine.update(yawRadians: 0.4, timestamp: 0)
        XCTAssertEqual(reading.state, .needsCalibration)
    }

    func testDwellAndHysteresis() {
        var engine = TurnawayEngine()
        engine.calibrate(yawRadians: 0)

        XCTAssertEqual(engine.update(yawRadians: degrees(32), timestamp: 0).state, .listening)
        XCTAssertEqual(engine.update(yawRadians: degrees(32), timestamp: 0.25).state, .turnaway)

        XCTAssertEqual(engine.update(yawRadians: degrees(22), timestamp: 0.4).state, .turnaway)
        XCTAssertEqual(engine.update(yawRadians: degrees(10), timestamp: 0.5).state, .turnaway)
        XCTAssertEqual(engine.update(yawRadians: degrees(10), timestamp: 0.85).state, .listening)
    }

    func testBriefGlanceDoesNotTriggerTurnaway() {
        var engine = TurnawayEngine()
        engine.calibrate(yawRadians: 0)

        XCTAssertEqual(engine.update(yawRadians: degrees(-40), timestamp: 1).state, .listening)
        XCTAssertEqual(engine.update(yawRadians: degrees(-5), timestamp: 1.1).state, .listening)
    }

    func testAngleWrapNearPi() {
        var engine = TurnawayEngine()
        engine.calibrate(yawRadians: degrees(179))

        let reading = engine.update(yawRadians: degrees(-179), timestamp: 0)
        XCTAssertEqual(reading.relativeYawDegrees, 2, accuracy: 0.001)
        XCTAssertEqual(reading.state, .listening)
    }

    private func degrees(_ value: Double) -> Double {
        value * .pi / 180
    }
}
