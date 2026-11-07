import Testing
@testable import MicAwayCore

@Suite("MenuStatusCopy")
struct MenuStatusCopyTests {
    private func copy(
        intentState: IntentState = .listening,
        motionConnected: Bool = true,
        motionLive: Bool? = nil,
        allowed: Bool = true,
        protectedNames: [String] = [],
        inputNames: [String] = ["Zoom"],
        selectedAppOnMic: Bool = true,
        unidentified: Bool = false,
        motionProblem: String? = nil
    ) -> MenuStatusCopy {
        MenuStatusCopy.resolve(
            turnawayEnabled: true,
            motionProblem: motionProblem,
            motionConnected: motionConnected,
            motionLive: motionLive ?? motionConnected,
            intentState: intentState,
            automaticMutingAllowed: allowed,
            protectedNamesOnMic: protectedNames,
            activeInputNames: inputNames,
            selectedAppOnMic: selectedAppOnMic,
            hasUnidentifiedInput: unidentified
        )
    }

    @Test func selectedZoomOnMicIsOnForThisCall() {
        let status = copy()
        #expect(status.title == "On for this call")
        #expect(status.title != "Inactive here")
        #expect(status.detail == "Live — you’re facing the Mac.")
    }

    @Test func turnedAwayInSelectedZoomSaysMuted() {
        #expect(copy(intentState: .turnaway).detail == "Muted — you’re turned away.")
    }

    @Test func noSelectedAppOnMicIsInactiveHere() {
        let status = copy(allowed: false, inputNames: [], selectedAppOnMic: false)
        #expect(status.title == "Inactive here")
        #expect(status.detail == "Waiting for a selected app to use the microphone.")
    }

    @Test func selectedAppBlockedByAnotherAppIsNotInactiveHere() {
        let status = copy(allowed: false, inputNames: ["Zoom", "Recorder"])
        #expect(status.title == "Standing by")
    }

    @Test func neverMuteDuringAppOnMicStandsBy() {
        let status = copy(allowed: false, protectedNames: ["FaceTime"])
        #expect(status.title == "Standing by")
        #expect(status.detail.contains("FaceTime"))
    }

    @Test func selectedAppWithoutMotionAsksForAirPods() {
        #expect(copy(motionConnected: false).title == "Needs AirPods")
    }

    @Test func motionProblemIsShownEvenWhenIdle() {
        // Without samples nothing can mute; "Ready" would hide that.
        let status = copy(inputNames: [], motionProblem: "Turn on Motion access.")
        #expect(status.title == "No head motion")
        #expect(status.detail == "Turn on Motion access.")
    }

    @Test func stalledMotionSaysTheMicStaysOpen() {
        let status = copy(intentState: .turnaway, motionLive: false)
        #expect(status.title == "Motion paused")
        #expect(!status.detail.contains("Muted"))
    }
}
