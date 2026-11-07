/// The input devices MicAway itself muted, keyed by Core Audio device UID.
///
/// UIDs, not `AudioObjectID`s: when a call switches AirPods to another
/// Bluetooth profile, macOS can recreate the input under a new object ID while
/// keeping it muted. A UID entry stays pending until that device is present and
/// confirmed unmuted, and the set is persisted so a relaunch after a crash can
/// still restore it. Devices MicAway did not mute are never touched.
public struct MutedInputLedger: Equatable, Sendable {
    public private(set) var deviceUIDs: Set<String>

    public init(deviceUIDs: Set<String> = []) {
        self.deviceUIDs = deviceUIDs
    }

    public var isEmpty: Bool { deviceUIDs.isEmpty }

    public func contains(_ uid: String) -> Bool { deviceUIDs.contains(uid) }

    public mutating func recordMuted(_ uid: String) {
        deviceUIDs.insert(uid)
    }

    public mutating func recordRestored(_ uid: String) {
        deviceUIDs.remove(uid)
    }

    /// The muted devices that are present now and can be unmuted. Absent ones
    /// stay in the ledger until they come back.
    public func restorable(presentDeviceUIDs: Set<String>) -> Set<String> {
        deviceUIDs.intersection(presentDeviceUIDs)
    }
}
