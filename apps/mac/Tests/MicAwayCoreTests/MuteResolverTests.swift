import Testing
@testable import MicAwayCore

struct MuteResolverTests {
    @Test func turnawayMutesWhenEnabledInAllowedApp() {
        #expect(MuteResolver.shouldMute(
            turnawayEnabled: true, microphoneInUse: true,
            applicationAllowed: true, motionLive: true, intentState: .turnaway))
    }

    @Test func listeningDoesNotMute() {
        #expect(!MuteResolver.shouldMute(
            turnawayEnabled: true, microphoneInUse: true,
            applicationAllowed: true, motionLive: true, intentState: .listening))
    }

    @Test func turnawayOffSuppressesMotionMute() {
        #expect(!MuteResolver.shouldMute(
            turnawayEnabled: false, microphoneInUse: true,
            applicationAllowed: true, motionLive: true, intentState: .turnaway))
    }

    @Test func blockedApplicationSuppressesMotionMute() {
        #expect(!MuteResolver.shouldMute(
            turnawayEnabled: true, microphoneInUse: true,
            applicationAllowed: false, motionLive: true, intentState: .turnaway))
    }

    @Test func lostMotionReleasesATurnawayMute() {
        // A call grabbing the AirPods mic can stop the motion stream while the
        // wearer is turned away. The last state must not hold the mute.
        #expect(!MuteResolver.shouldMute(
            turnawayEnabled: true, microphoneInUse: true,
            applicationAllowed: true, motionLive: false, intentState: .turnaway))
    }

    @Test func idleMicIsNeverMuted() {
        // Every app mode with nothing recording: muting here would hand the
        // next call (e.g. a Slack huddle) an already-muted system mic.
        #expect(!MuteResolver.shouldMute(
            turnawayEnabled: true, microphoneInUse: false,
            applicationAllowed: true, motionLive: true, intentState: .turnaway))
    }

    @Test func motionIsLiveOnlyWhenConnectedWithFreshSamples() {
        #expect(MuteResolver.motionIsLive(connected: true, secondsSinceLastSample: 0.2))
        #expect(!MuteResolver.motionIsLive(connected: true, secondsSinceLastSample: 5))
        #expect(!MuteResolver.motionIsLive(connected: true, secondsSinceLastSample: nil))
        #expect(!MuteResolver.motionIsLive(connected: false, secondsSinceLastSample: 0.2))
    }
}
