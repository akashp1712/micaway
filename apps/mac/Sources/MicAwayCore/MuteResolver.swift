/// Single source of truth for whether microphone input should be muted.
///
/// The motion gate mutes only when the turnaway feature is enabled, the active
/// app is allowed, and the wearer has turned away from the Mac.
public enum MuteResolver {
    public static func shouldMute(
        turnawayEnabled: Bool,
        applicationAllowed: Bool,
        intentState: IntentState
    ) -> Bool {
        return turnawayEnabled
            && applicationAllowed
            && intentState == .turnaway
    }
}
