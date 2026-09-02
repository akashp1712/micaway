import Testing
@testable import MicAwayCore

struct MuteResolverTests {
    @Test func manualMuteForcesMute() {
        #expect(MuteResolver.shouldMute(
            manualMuteEngaged: true, guardEnabled: false,
            microphoneGateEnabled: false, intentState: .listening))
    }

    @Test func turnawayMutesWhenGuardAndGateOn() {
        #expect(MuteResolver.shouldMute(
            manualMuteEngaged: false, guardEnabled: true,
            microphoneGateEnabled: true, intentState: .turnaway))
    }

    @Test func listeningDoesNotMute() {
        #expect(!MuteResolver.shouldMute(
            manualMuteEngaged: false, guardEnabled: true,
            microphoneGateEnabled: true, intentState: .listening))
    }

    @Test func guardOffSuppressesMotionMute() {
        #expect(!MuteResolver.shouldMute(
            manualMuteEngaged: false, guardEnabled: false,
            microphoneGateEnabled: true, intentState: .turnaway))
    }

    @Test func gateOffSuppressesMotionMute() {
        #expect(!MuteResolver.shouldMute(
            manualMuteEngaged: false, guardEnabled: true,
            microphoneGateEnabled: false, intentState: .turnaway))
    }
}
