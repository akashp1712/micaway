import Testing
@testable import MicAwayCore

@Suite("ProtectedApplicationPolicy")
struct ProtectedApplicationPolicyTests {
    @Test func protectedAppOnMicBlocksMuting() {
        #expect(ProtectedApplicationPolicy.blocksMuting(
            protectedBundleIdentifiers: ["us.zoom.xos"],
            activeInputBundleIdentifiers: ["us.zoom.xos"]
        ))
    }

    @Test func protectedAppAlongsideDictationBlocksMuting() {
        #expect(ProtectedApplicationPolicy.blocksMuting(
            protectedBundleIdentifiers: ["us.zoom.xos"],
            activeInputBundleIdentifiers: [
                "org.example.dictation",
                "us.zoom.xos",
            ]
        ))
    }

    @Test func unprotectedInputDoesNotBlockMuting() {
        #expect(!ProtectedApplicationPolicy.blocksMuting(
            protectedBundleIdentifiers: ["us.zoom.xos"],
            activeInputBundleIdentifiers: ["org.example.dictation"]
        ))
    }

    @Test func noActiveInputDoesNotBlockMuting() {
        #expect(!ProtectedApplicationPolicy.blocksMuting(
            protectedBundleIdentifiers: ["us.zoom.xos"],
            activeInputBundleIdentifiers: []
        ))
    }

    @Test func emptyProtectedListDoesNotBlockMuting() {
        #expect(!ProtectedApplicationPolicy.blocksMuting(
            protectedBundleIdentifiers: [],
            activeInputBundleIdentifiers: ["us.zoom.xos"]
        ))
    }
}
