import Testing
@testable import MicAwayCore

@Suite("ApplicationListDefaults")
struct ApplicationListDefaultsTests {
    private let zoom = ScopedApplication(bundleIdentifier: "us.zoom.xos", name: "Zoom")
    private let chrome = ScopedApplication(bundleIdentifier: "com.google.Chrome", name: "Google Chrome")

    private var legacySix: [ScopedApplication] { ApplicationListDefaults.callApplications }

    @Test func freshInstallAllowsCallAppsAndBrowsersAndProtectsNothing() {
        let lists = ApplicationListDefaults.resolve(
            storedAllowed: nil,
            storedProtected: nil,
            didSeedLegacyDefaults: false,
            didApplyCurrentDefaults: false
        )
        #expect(lists.protected.isEmpty)
        let allowed = Set(lists.allowed.map(\.bundleIdentifier))
        for identifier in [
            "us.zoom.xos", "com.microsoft.teams2", "com.tinyspeck.slackmacgap",
            "com.apple.FaceTime", "com.hnc.Discord", "com.cisco.webexmeetingsapp",
            "com.google.Chrome", "com.apple.Safari", "company.thebrowser.Browser",
            "org.mozilla.firefox",
        ] {
            #expect(allowed.contains(identifier))
        }
    }

    @Test func untouchedLegacySeedMovesIntoAllowed() {
        let lists = ApplicationListDefaults.resolve(
            storedAllowed: [],
            storedProtected: legacySix.reversed(),
            didSeedLegacyDefaults: true,
            didApplyCurrentDefaults: false
        )
        #expect(Set(lists.allowed) == Set(legacySix))
        #expect(lists.allowed.count == 6)
        #expect(lists.protected.isEmpty)
    }

    @Test func editedNeverMuteListIsNotOverwritten() {
        let edited = legacySix.filter { $0 != zoom } + [chrome]
        let lists = ApplicationListDefaults.resolve(
            storedAllowed: [],
            storedProtected: edited,
            didSeedLegacyDefaults: true,
            didApplyCurrentDefaults: false
        )
        #expect(lists.protected == edited)
        #expect(lists.allowed.isEmpty)
    }

    @Test func editedAllowedListIsNotOverwritten() {
        let lists = ApplicationListDefaults.resolve(
            storedAllowed: [chrome],
            storedProtected: legacySix,
            didSeedLegacyDefaults: true,
            didApplyCurrentDefaults: false
        )
        #expect(lists.allowed == [chrome])
        #expect(lists.protected == legacySix)
    }

    @Test func migrationRunsOnlyOnce() {
        let lists = ApplicationListDefaults.resolve(
            storedAllowed: [],
            storedProtected: legacySix,
            didSeedLegacyDefaults: true,
            didApplyCurrentDefaults: true
        )
        #expect(lists.allowed.isEmpty)
        #expect(lists.protected == legacySix)
    }

    @Test func freshSeedLetsZoomMute() {
        let lists = ApplicationListDefaults.resolve(
            storedAllowed: nil,
            storedProtected: nil,
            didSeedLegacyDefaults: false,
            didApplyCurrentDefaults: false
        )
        #expect(!ProtectedApplicationPolicy.blocksMuting(
            protectedBundleIdentifiers: Set(lists.protected.map(\.bundleIdentifier)),
            activeInputBundleIdentifiers: ["us.zoom.xos"]
        ))
        #expect(ApplicationScopePolicy.allowsAutomaticMuting(
            selectedBundleIdentifiers: Set(lists.allowed.map(\.bundleIdentifier)),
            activeInputBundleIdentifiers: ["us.zoom.xos"],
            hasUnidentifiedInputApplication: false
        ))
    }
}
