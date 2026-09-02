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
}
