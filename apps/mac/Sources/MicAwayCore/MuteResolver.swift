/// Single source of truth for whether microphone input should be muted.
///
/// Manual mute always wins. Otherwise the motion gate mutes only when the
/// turnaway guard and the microphone gate are both enabled and the wearer has
/// turned away from the Mac.
public enum MuteResolver {
    public static func shouldMute(
        manualMuteEngaged: Bool,
        guardEnabled: Bool,
        microphoneGateEnabled: Bool,
        intentState: IntentState
    ) -> Bool {
        if manualMuteEngaged { return true }
        return guardEnabled && microphoneGateEnabled && intentState == .turnaway
    }
}
