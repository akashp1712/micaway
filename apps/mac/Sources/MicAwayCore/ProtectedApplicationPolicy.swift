/// Opt-in exception list ("Never mute during"): calls the user wants left
/// alone. While any listed app is capturing input, MicAway does not mute, in
/// every application-scope mode. Empty by default.
///
/// MicAway mutes the macOS input device (`kAudioDevicePropertyMute`). Some
/// apps mirror that into their own mic button and some do not, so this list
/// is for calls where the user wants no automatic change at all.
public enum ProtectedApplicationPolicy {
    /// Returns `true` when automatic muting must be suppressed because at least
    /// one active-input app is protected.
    public static func blocksMuting(
        protectedBundleIdentifiers: Set<String>,
        activeInputBundleIdentifiers: Set<String>
    ) -> Bool {
        !protectedBundleIdentifiers.isDisjoint(with: activeInputBundleIdentifiers)
    }
}
