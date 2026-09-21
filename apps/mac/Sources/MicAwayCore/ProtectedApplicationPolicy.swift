/// Safety net that keeps MicAway's hands off the microphone while a protected
/// app — typically a real-time meeting or call app — is actively capturing
/// input.
///
/// macOS exposes only a device-level mute (`kAudioDevicePropertyMute`), which
/// meeting apps observe and mirror into their own UI. Muting that shared device
/// on turn-away therefore flips the mic-off indicator inside Google Meet, Zoom,
/// and the like, disturbing a live call. Standing down whenever a protected app
/// is on the mic avoids that, and it does so in every application-scope mode.
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
