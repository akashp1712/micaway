import Foundation

/// Single source of truth for whether microphone input should be muted.
///
/// The motion gate mutes only when the turnaway feature is enabled, an app is
/// actually using the mic, that app is allowed, motion is live, and the wearer
/// has turned away from the Mac. Muting an idle mic would greet the next call
/// with a muted system input, which apps like Slack flag as a problem.
public enum MuteResolver {
    /// Head-motion samples older than this no longer justify holding a mute.
    public static let maxSampleAgeSeconds: TimeInterval = 1.5

    public static func shouldMute(
        turnawayEnabled: Bool,
        microphoneInUse: Bool,
        applicationAllowed: Bool,
        motionLive: Bool,
        intentState: IntentState
    ) -> Bool {
        return turnawayEnabled
            && microphoneInUse
            && applicationAllowed
            && motionLive
            && intentState == .turnaway
    }

    /// Motion is live when AirPods report connected and a sample arrived
    /// recently. A call can switch AirPods to a Bluetooth profile that stops the
    /// motion stream mid-turn; without this, the last "turned away" reading
    /// would hold the mic muted with nothing left to release it.
    public static func motionIsLive(
        connected: Bool,
        secondsSinceLastSample: TimeInterval?
    ) -> Bool {
        guard connected, let secondsSinceLastSample else { return false }
        return secondsSinceLastSample <= maxSampleAgeSeconds
    }
}
