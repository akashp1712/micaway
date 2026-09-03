import Testing
@testable import MicAwayCore

@Suite("ApplicationScopePolicy")
struct ApplicationScopePolicyTests {
    @Test func selectedVoiceAppAllowsAutomaticMuting() {
        #expect(ApplicationScopePolicy.allowsAutomaticMuting(
            selectedBundleIdentifiers: ["org.example.dictation"],
            activeInputBundleIdentifiers: ["org.example.dictation"],
            hasUnidentifiedInputApplication: false
        ))
    }

    @Test func meetingAppVetoesAutomaticMuting() {
        #expect(!ApplicationScopePolicy.allowsAutomaticMuting(
            selectedBundleIdentifiers: ["org.example.dictation"],
            activeInputBundleIdentifiers: [
                "org.example.dictation",
                "org.example.meeting",
            ],
            hasUnidentifiedInputApplication: false
        ))
    }

    @Test func noActiveInputDoesNotMute() {
        #expect(!ApplicationScopePolicy.allowsAutomaticMuting(
            selectedBundleIdentifiers: ["org.example.dictation"],
            activeInputBundleIdentifiers: [],
            hasUnidentifiedInputApplication: false
        ))
    }

    @Test func unidentifiedInputFailsOpen() {
        #expect(!ApplicationScopePolicy.allowsAutomaticMuting(
            selectedBundleIdentifiers: ["org.example.dictation"],
            activeInputBundleIdentifiers: ["org.example.dictation"],
            hasUnidentifiedInputApplication: true
        ))
    }
}
