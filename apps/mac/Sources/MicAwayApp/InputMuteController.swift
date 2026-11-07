@preconcurrency import CoreAudio
import Foundation
import MicAwayCore

final class InputMuteController: @unchecked Sendable {
    enum GateError: LocalizedError {
        case noInputDevices
        case coreAudio(OSStatus)
        case stillMuted

        var errorDescription: String? {
            switch self {
            case .noInputDevices:
                return "No microphone with a system mute switch is available."
            case let .coreAudio(status):
                return "Core Audio returned error \(status)."
            case .stillMuted:
                return "macOS kept the microphone muted. MicAway will keep trying to unmute it."
            }
        }
    }

    private struct InputDevice {
        let id: AudioObjectID
        let uid: String
    }

    private static let ledgerDefaultsKey = "mutedInputDeviceUIDs"

    /// Inputs MicAway muted, by device UID. Persisted so a relaunch after a
    /// crash or forced quit still restores them.
    private var ledger: MutedInputLedger {
        didSet {
            guard ledger != oldValue else { return }
            UserDefaults.standard.set(
                ledger.deviceUIDs.sorted(),
                forKey: Self.ledgerDefaultsKey
            )
        }
    }

    init() {
        ledger = MutedInputLedger(deviceUIDs: Set(
            UserDefaults.standard.stringArray(forKey: Self.ledgerDefaultsKey) ?? []
        ))
    }

    /// True while any input MicAway muted has not been confirmed unmuted,
    /// including one that is temporarily absent.
    var holdsMutes: Bool { !ledger.isEmpty }

    func muteForTurnaway() throws {
        let devices = try muteCapableInputDevices()
        guard !devices.isEmpty else { throw GateError.noInputDevices }
        let address = muteAddress()
        var firstError: Error?

        for device in devices {
            do {
                let alreadyMuted = try readMute(device: device.id, address: address)
                if ledger.contains(device.uid) {
                    // Ours. Re-assert if a recreated device came back unmuted.
                    if !alreadyMuted {
                        try writeMute(true, device: device.id, address: address)
                    }
                    continue
                }
                // Muted by someone else: not ours to change or to restore.
                guard !alreadyMuted else { continue }
                try writeMute(true, device: device.id, address: address)
                ledger.recordMuted(device.uid)
            } catch {
                firstError = firstError ?? error
            }
        }

        if ledger.isEmpty, let firstError {
            throw firstError
        }
    }

    /// Unmutes every present input MicAway muted, confirming each by reading
    /// it back. Inputs that are absent (for example AirPods mid profile
    /// switch) or that macOS kept muted stay in the ledger for the next call.
    func restoreIfNeeded() throws {
        guard !ledger.isEmpty else { return }
        let address = muteAddress()
        var idsByUID: [String: AudioObjectID] = [:]
        for device in try muteCapableInputDevices() {
            idsByUID[device.uid] = idsByUID[device.uid] ?? device.id
        }
        var firstError: Error?

        for uid in ledger.restorable(presentDeviceUIDs: Set(idsByUID.keys)) {
            guard let id = idsByUID[uid] else { continue }
            do {
                if try readMute(device: id, address: address) {
                    try writeMute(false, device: id, address: address)
                }
                guard try !readMute(device: id, address: address) else {
                    throw GateError.stillMuted
                }
                ledger.recordRestored(uid)
            } catch {
                firstError = firstError ?? error
            }
        }

        if let firstError { throw firstError }
    }

    private func muteCapableInputDevices() throws -> [InputDevice] {
        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var devicesSize: UInt32 = 0
        let sizeStatus = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddress,
            0,
            nil,
            &devicesSize
        )
        guard sizeStatus == noErr else { throw GateError.coreAudio(sizeStatus) }

        let deviceCount = Int(devicesSize) / MemoryLayout<AudioObjectID>.size
        var devices = [AudioObjectID](repeating: kAudioObjectUnknown, count: deviceCount)
        let dataStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddress,
            0,
            nil,
            &devicesSize,
            &devices
        )
        guard dataStatus == noErr else { throw GateError.coreAudio(dataStatus) }

        let address = muteAddress()
        return devices.compactMap { id in
            guard isPropertySettable(id, address: address),
                  let uid = deviceUID(id) else { return nil }
            return InputDevice(id: id, uid: uid)
        }
    }

    private func deviceUID(_ device: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var uid: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &uid)
        guard status == noErr, let uid else { return nil }
        return uid.takeRetainedValue() as String
    }

    private func muteAddress() -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    private func readMute(
        device: AudioObjectID,
        address originalAddress: AudioObjectPropertyAddress
    ) throws -> Bool {
        var address = originalAddress
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value)
        guard status == noErr else { throw GateError.coreAudio(status) }
        return value != 0
    }

    private func writeMute(
        _ muted: Bool,
        device: AudioObjectID,
        address originalAddress: AudioObjectPropertyAddress
    ) throws {
        var address = originalAddress
        var value: UInt32 = muted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectSetPropertyData(device, &address, 0, nil, size, &value)
        guard status == noErr else { throw GateError.coreAudio(status) }
    }
}

private func isPropertySettable(
    _ object: AudioObjectID,
    address originalAddress: AudioObjectPropertyAddress
) -> Bool {
    var address = originalAddress
    var settable = DarwinBoolean(false)
    let status = AudioObjectIsPropertySettable(object, &address, &settable)
    return status == noErr && settable.boolValue
}
