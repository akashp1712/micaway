@preconcurrency import CoreAudio
import Foundation

final class DefaultInputMuteController: @unchecked Sendable {
    enum GateError: LocalizedError {
        case noDefaultInput
        case muteNotSupported
        case coreAudio(OSStatus)

        var errorDescription: String? {
            switch self {
            case .noDefaultInput:
                return "No default input device is available."
            case .muteNotSupported:
                return "This microphone does not expose a system mute switch."
            case let .coreAudio(status):
                return "Core Audio returned error \(status)."
            }
        }
    }

    private var deviceMutedByUs: AudioObjectID?

    func canMuteDefaultInput() -> Bool {
        guard let device = try? defaultInputDevice() else { return false }
        return isPropertySettable(device, address: muteAddress())
    }

    func muteForTurnaway() throws {
        let device = try defaultInputDevice()
        let address = muteAddress()

        guard isPropertySettable(device, address: address) else {
            throw GateError.muteNotSupported
        }

        let alreadyMuted = try readMute(device: device, address: address)
        guard !alreadyMuted else { return }

        try writeMute(true, device: device, address: address)
        deviceMutedByUs = device
    }

    func restoreIfNeeded() throws {
        guard let device = deviceMutedByUs else { return }
        defer { deviceMutedByUs = nil }

        let address = muteAddress()
        guard isPropertySettable(device, address: address) else { return }
        try writeMute(false, device: device, address: address)
    }

    private func defaultInputDevice() throws -> AudioObjectID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &device
        )
        guard status == noErr else { throw GateError.coreAudio(status) }
        guard device != kAudioObjectUnknown else { throw GateError.noDefaultInput }
        return device
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
