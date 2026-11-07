/// Headline and detail shown at the top of the menu.
public struct MenuStatusCopy: Equatable, Sendable {
    public let title: String
    public let detail: String

    public init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }
}

public extension MenuStatusCopy {
    /// Single source of truth for the menu's status copy.
    ///
    /// "Inactive here" is reserved for the case where no selected app has the
    /// mic. When a selected app is on the mic but something else blocks
    /// muting, the menu says "Standing by" and names the reason.
    ///
    /// A motion problem (access off, or AirPods sending no samples) outranks
    /// everything but Paused: without motion nothing can mute, and saying
    /// "Ready" would hide that until the user's next call.
    static func resolve(
        turnawayEnabled: Bool,
        motionProblem: String? = nil,
        motionConnected: Bool,
        motionLive: Bool,
        intentState: IntentState,
        automaticMutingAllowed: Bool,
        protectedNamesOnMic: [String],
        activeInputNames: [String],
        selectedAppOnMic: Bool,
        hasUnidentifiedInput: Bool
    ) -> MenuStatusCopy {
        if !turnawayEnabled {
            return MenuStatusCopy(
                title: "Paused",
                detail: "Turnaway muting is off. Your other mic controls are unchanged."
            )
        }
        if let motionProblem {
            return MenuStatusCopy(title: "No head motion", detail: motionProblem)
        }
        if !protectedNamesOnMic.isEmpty {
            let names = protectedNamesOnMic.joined(separator: ", ")
            return MenuStatusCopy(
                title: "Standing by",
                detail: "Leaving \(names) alone, as set in Never mute during."
            )
        }
        if !automaticMutingAllowed {
            if selectedAppOnMic {
                return MenuStatusCopy(
                    title: "Standing by",
                    detail: hasUnidentifiedInput
                        ? "An unidentified app also has the mic, so it stays open."
                        : "Another app also has the mic, so it stays open."
                )
            }
            if hasUnidentifiedInput {
                return MenuStatusCopy(
                    title: "Inactive here",
                    detail: "MicAway could not identify the app on the mic, so it stays open."
                )
            }
            if activeInputNames.isEmpty {
                return MenuStatusCopy(
                    title: "Inactive here",
                    detail: "Waiting for a selected app to use the microphone."
                )
            }
            let names = activeInputNames.joined(separator: ", ")
            let verb = activeInputNames.count == 1 ? "is" : "are"
            return MenuStatusCopy(
                title: "Inactive here",
                detail: "\(names) \(verb) not in Allowed apps."
            )
        }
        if activeInputNames.isEmpty && !hasUnidentifiedInput {
            return MenuStatusCopy(
                title: "Ready",
                detail: "Turns on when an app uses the microphone."
            )
        }
        if !motionConnected {
            return MenuStatusCopy(
                title: "Needs AirPods",
                detail: "Put in your AirPods so turning away can mute the mic."
            )
        }
        if !motionLive {
            return MenuStatusCopy(
                title: "Motion paused",
                detail: "The mic stays open until AirPods motion returns."
            )
        }
        return switch intentState {
        case .needsCalibration:
            MenuStatusCopy(title: "On for this call", detail: "Face your Mac and select Calibrate once.")
        case .listening:
            MenuStatusCopy(title: "On for this call", detail: "Live — you’re facing the Mac.")
        case .turnaway:
            MenuStatusCopy(title: "On for this call", detail: "Muted — you’re turned away.")
        }
    }
}
