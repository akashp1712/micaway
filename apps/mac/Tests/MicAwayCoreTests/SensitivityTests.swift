import Testing
@testable import MicAwayCore

struct SensitivityTests {
    @Test func defaultIsMedium() {
        #expect(Sensitivity.default == .medium)
    }

    @Test func mediumMatchesEngineDefaults() {
        #expect(Sensitivity.medium.configuration == TurnawayConfiguration())
    }

    @Test func lowerSensitivityNeedsABiggerTurn() {
        // Enter threshold grows as sensitivity drops: high < medium < low.
        #expect(Sensitivity.high.configuration.enterThresholdDegrees
                < Sensitivity.medium.configuration.enterThresholdDegrees)
        #expect(Sensitivity.medium.configuration.enterThresholdDegrees
                < Sensitivity.low.configuration.enterThresholdDegrees)
    }

    @Test func everyPresetKeepsHysteresis() {
        // enter must stay above exit or the configuration precondition traps.
        for sensitivity in Sensitivity.allCases {
            let config = sensitivity.configuration
            #expect(config.enterThresholdDegrees > config.exitThresholdDegrees)
        }
    }

    @Test func presetOrderIsLowToHigh() {
        #expect(Sensitivity.allCases == [.low, .medium, .high])
    }

    // MARK: - Continuous slider mapping

    @Test func forTurnAngleUsesTheGivenEnterThreshold() {
        let config = TurnawayConfiguration.forTurnAngle(enterThresholdDegrees: 45)
        #expect(config.enterThresholdDegrees == 45)
        #expect(config.exitThresholdDegrees == 28) // round(45 * 0.62)
    }

    @Test func forTurnAngleClampsToLimits() {
        #expect(TurnawayConfiguration.forTurnAngle(enterThresholdDegrees: 5)
                .enterThresholdDegrees == SensitivityLimits.minDegrees)
        #expect(TurnawayConfiguration.forTurnAngle(enterThresholdDegrees: 120)
                .enterThresholdDegrees == SensitivityLimits.maxDegrees)
    }

    @Test func forTurnAngleKeepsHysteresisAcrossTheRange() {
        for degrees in stride(from: SensitivityLimits.minDegrees,
                              through: SensitivityLimits.maxDegrees,
                              by: 1) {
            let config = TurnawayConfiguration.forTurnAngle(enterThresholdDegrees: degrees)
            #expect(config.enterThresholdDegrees > config.exitThresholdDegrees)
        }
    }

    @Test func forTurnAngleGivesBiggerTurnsALongerDwell() {
        let sensitive = TurnawayConfiguration.forTurnAngle(
            enterThresholdDegrees: SensitivityLimits.minDegrees
        )
        let deliberate = TurnawayConfiguration.forTurnAngle(
            enterThresholdDegrees: SensitivityLimits.maxDegrees
        )
        #expect(sensitive.enterDwellSeconds < deliberate.enterDwellSeconds)
        #expect(deliberate.exitThresholdDegrees > sensitive.exitThresholdDegrees)
    }
}
