import Testing
@testable import MicAwayCore

struct MuteResolverTests {
    @Test func turnawayMutesWhenEnabledInAllowedApp() {
        #expect(MuteResolver.shouldMute(
            turnawayEnabled: true,
            applicationAllowed: true, intentState: .turnaway))
    }

    @Test func listeningDoesNotMute() {
        #expect(!MuteResolver.shouldMute(
            turnawayEnabled: true,
            applicationAllowed: true, intentState: .listening))
    }

    @Test func turnawayOffSuppressesMotionMute() {
        #expect(!MuteResolver.shouldMute(
            turnawayEnabled: false,
            applicationAllowed: true, intentState: .turnaway))
    }

    @Test func blockedApplicationSuppressesMotionMute() {
        #expect(!MuteResolver.shouldMute(
            turnawayEnabled: true,
            applicationAllowed: false, intentState: .turnaway))
    }
}
