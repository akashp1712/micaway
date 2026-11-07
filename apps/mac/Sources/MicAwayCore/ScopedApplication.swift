/// An app identified by bundle ID, as stored in Allowed apps and Never mute
/// during. Persisted as JSON in UserDefaults; keep the property names stable.
public struct ScopedApplication: Codable, Hashable, Identifiable, Sendable {
    public let bundleIdentifier: String
    public let name: String

    public var id: String { bundleIdentifier }

    public init(bundleIdentifier: String, name: String) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
    }
}
