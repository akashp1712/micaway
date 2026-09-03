/// Safety policy for Selected Apps mode.
///
/// Automatic muting is allowed only when Core Audio identifies at least one
/// input-consuming app and every identified app is selected. Any unidentified
/// input consumer keeps the microphone open.
public enum ApplicationScopePolicy {
    public static func allowsAutomaticMuting(
        selectedBundleIdentifiers: Set<String>,
        activeInputBundleIdentifiers: Set<String>,
        hasUnidentifiedInputApplication: Bool
    ) -> Bool {
        guard !hasUnidentifiedInputApplication,
              !activeInputBundleIdentifiers.isEmpty
        else { return false }
        return activeInputBundleIdentifiers.isSubset(of: selectedBundleIdentifiers)
    }
}
