import Foundation
import MicAwayCore

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

// TurnawayEngine smoke checks (mirror the canonical swift-testing suite).
var engine = TurnawayEngine()
check(engine.update(yawRadians: 0.4, timestamp: 0).state == .needsCalibration,
      "engine requires calibration first")

// Default engine == Medium sensitivity: enter 45°, exit 28°, dwell 0.40/0.34s.
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

// Sensitivity presets map to increasing enter thresholds.
check(Sensitivity.default == .medium, "default sensitivity is medium")
check(Sensitivity.medium.configuration == TurnawayConfiguration(),
      "medium sensitivity matches engine defaults")
check(Sensitivity.high.configuration.enterThresholdDegrees
        < Sensitivity.low.configuration.enterThresholdDegrees,
      "high sensitivity needs a smaller turn than low")

// MuteResolver checks
check(MuteResolver.shouldMute(manualMuteEngaged: true, guardEnabled: false,
                              microphoneGateEnabled: false, intentState: .listening),
      "manual mute forces mute regardless of gates")
check(MuteResolver.shouldMute(manualMuteEngaged: false, guardEnabled: true,
                              microphoneGateEnabled: true, intentState: .turnaway),
      "turnaway mutes when guard + gate on")
check(!MuteResolver.shouldMute(manualMuteEngaged: false, guardEnabled: true,
                               microphoneGateEnabled: true, intentState: .listening),
      "listening does not mute")
check(!MuteResolver.shouldMute(manualMuteEngaged: false, guardEnabled: false,
                               microphoneGateEnabled: true, intentState: .turnaway),
      "guard off suppresses motion mute")
check(!MuteResolver.shouldMute(manualMuteEngaged: false, guardEnabled: true,
                               microphoneGateEnabled: false, intentState: .turnaway),
      "gate off suppresses motion mute")

if failures == 0 {
    print("ALL PASS")
    exit(0)
} else {
    print("\(failures) FAILURE(S)")
    exit(1)
}
