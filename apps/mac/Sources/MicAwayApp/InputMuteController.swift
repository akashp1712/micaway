@preconcurrency import CoreAudio
import Foundation

final class InputMuteController: @unchecked Sendable {
    enum GateError: LocalizedError {
        case noInputDevices
        case coreAudio(OSStatus)

        var errorDescription: String? {
            switch self {
            case .noInputDevices:
                return "No microphone with a system mute switch is available."
            case let .coreAudio(status):
                return "Core Audio returned error \(status)."
            }
        }
    }

    private var devicesMutedByUs = Set<AudioObjectID>()

    func muteForTurnaway() throws {
        let devices = try muteCapableInputDevices()
        guard !devices.isEmpty else { throw GateError.noInputDevices }
        let address = muteAddress()
        var firstError: Error?

        for device in devices where !devicesMutedByUs.contains(device) {
            do {
                guard try !readMute(device: device, address: address) else { continue }
                try writeMute(true, device: device, address: address)
                devicesMutedByUs.insert(device)
            } catch {
                firstError = firstError ?? error
            }
        }

        if devicesMutedByUs.isEmpty, let firstError {
            throw firstError
        }
    }

    func restoreIfNeeded() throws {
        guard !devicesMutedByUs.isEmpty else { return }
        let address = muteAddress()
        var firstError: Error?

        for device in Array(devicesMutedByUs) {
            do {
                if isPropertySettable(device, address: address) {
                    try writeMute(false, device: device, address: address)
                }
                devicesMutedByUs.remove(device)
            } catch {
                firstError = firstError ?? error
            }
        }

        if let firstError { throw firstError }
    }

    private func muteCapableInputDevices() throws -> [AudioObjectID] {
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
        return devices.filter { isPropertySettable($0, address: address) }
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
