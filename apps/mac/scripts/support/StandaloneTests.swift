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

engine.calibrate(yawRadians: 0)
check(engine.update(yawRadians: degrees(32), timestamp: 0).state == .listening,
      "engine stays listening before enter dwell")
check(engine.update(yawRadians: degrees(32), timestamp: 0.25).state == .turnaway,
      "engine enters turnaway after enter dwell")
check(engine.update(yawRadians: degrees(22), timestamp: 0.4).state == .turnaway,
      "engine stays turnaway while still past exit threshold")
check(engine.update(yawRadians: degrees(10), timestamp: 0.5).state == .turnaway,
      "engine stays turnaway before exit dwell elapses")
check(engine.update(yawRadians: degrees(10), timestamp: 0.85).state == .listening,
      "engine exits turnaway after exit dwell")

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
