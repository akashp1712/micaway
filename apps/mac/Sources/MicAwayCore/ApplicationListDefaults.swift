/// First-launch contents of Allowed apps and Never mute during, plus the
/// one-time migration away from the original seed.
///
/// The original seed put six call apps on Never mute during, so MicAway stood
/// down in exactly the calls it exists for. The current seed allows call apps
/// and browsers (for Meet and other browser calls) and protects nothing.
/// Dictation apps are not seeded; users add them through Allowed apps.
public enum ApplicationListDefaults {
    /// Native call apps. Bundle IDs for apps that are not installed never match
    /// and are harmless.
    public static let callApplications: [ScopedApplication] = [
        ScopedApplication(bundleIdentifier: "us.zoom.xos", name: "Zoom"),
        ScopedApplication(bundleIdentifier: "com.microsoft.teams2", name: "Microsoft Teams"),
        ScopedApplication(bundleIdentifier: "com.tinyspeck.slackmacgap", name: "Slack"),
        ScopedApplication(bundleIdentifier: "com.apple.FaceTime", name: "FaceTime"),
        ScopedApplication(bundleIdentifier: "com.hnc.Discord", name: "Discord"),
        ScopedApplication(bundleIdentifier: "com.cisco.webexmeetingsapp", name: "Webex"),
    ]

    /// Browsers, so Google Meet and other browser calls work without setup.
    /// Core Audio reports the browser, not the tab.
    public static let browserApplications: [ScopedApplication] = [
        ScopedApplication(bundleIdentifier: "com.google.Chrome", name: "Google Chrome"),
        ScopedApplication(bundleIdentifier: "com.apple.Safari", name: "Safari"),
        ScopedApplication(bundleIdentifier: "company.thebrowser.Browser", name: "Arc"),
        ScopedApplication(bundleIdentifier: "org.mozilla.firefox", name: "Firefox"),
    ]

    public static let allowedApplications = callApplications + browserApplications
    public static let protectedApplications: [ScopedApplication] = []

    /// Exactly what earlier versions seeded onto Never mute during.
    public static let legacyProtectedSeed: Set<String> = Set(
        callApplications.map(\.bundleIdentifier)
    )

    public struct Lists: Equatable, Sendable {
        public var allowed: [ScopedApplication]
        public var protected: [ScopedApplication]

        public init(allowed: [ScopedApplication], protected: [ScopedApplication]) {
            self.allowed = allowed
            self.protected = protected
        }
    }

    /// Resolves the lists to use at launch.
    ///
    /// - `storedAllowed` / `storedProtected`: the persisted lists, or `nil`
    ///   when nothing was ever saved.
    /// - `didSeedLegacyDefaults`: the old install wrote its six-app seed.
    /// - `didApplyCurrentDefaults`: this seed/migration already ran once.
    ///
    /// A fresh install gets the current seed. An install still holding the
    /// untouched legacy seed (six protected, nothing allowed) moves those six
    /// into Allowed and clears Never mute during. Anything the user edited is
    /// left exactly as stored.
    public static func resolve(
        storedAllowed: [ScopedApplication]?,
        storedProtected: [ScopedApplication]?,
        didSeedLegacyDefaults: Bool,
        didApplyCurrentDefaults: Bool
    ) -> Lists {
        let stored = Lists(allowed: storedAllowed ?? [], protected: storedProtected ?? [])
        guard !didApplyCurrentDefaults else { return stored }

        let isFreshInstall = storedAllowed == nil
            && storedProtected == nil
            && !didSeedLegacyDefaults
        if isFreshInstall {
            return Lists(allowed: allowedApplications, protected: protectedApplications)
        }

        let protectedIdentifiers = stored.protected.map(\.bundleIdentifier)
        let holdsUntouchedLegacySeed = stored.allowed.isEmpty
            && protectedIdentifiers.count == legacyProtectedSeed.count
            && Set(protectedIdentifiers) == legacyProtectedSeed
        if holdsUntouchedLegacySeed {
            return Lists(allowed: stored.protected, protected: [])
        }

        return stored
    }
}
