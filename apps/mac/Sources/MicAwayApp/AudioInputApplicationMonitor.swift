import AppKit
@preconcurrency import CoreAudio
import Foundation

struct AudioInputSnapshot: Equatable {
    var applications: [ScopedApplication] = []
    var hasUnidentifiedApplication = false
}

/// Polls Core Audio's process objects so app scoping follows the software that
/// is actually consuming microphone input, rather than whichever window happens
/// to be in front. Polling keeps this small and avoids retaining a listener for
/// every short-lived browser or helper process.
@MainActor
final class AudioInputApplicationMonitor {
    var onChange: ((AudioInputSnapshot) -> Void)?

    private var timer: Timer?
    private var latestSnapshot = AudioInputSnapshot()

    func start() {
        guard timer == nil else { return }
        refresh()
        let timer = Timer(timeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        let snapshot = Self.readSnapshot()
        guard snapshot != latestSnapshot else { return }
        latestSnapshot = snapshot
        onChange?(snapshot)
    }

    private static func readSnapshot() -> AudioInputSnapshot {
        guard let processObjects = readProcessObjects() else {
            return AudioInputSnapshot(hasUnidentifiedApplication: true)
        }

        var applicationsByBundleID: [String: ScopedApplication] = [:]
        var hasUnidentifiedApplication = false

        for processObject in processObjects where isRunningInput(processObject) {
            guard let bundleIdentifier = readBundleIdentifier(processObject),
                  !bundleIdentifier.isEmpty
            else {
                hasUnidentifiedApplication = true
                continue
            }

            let name = NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleIdentifier
            ).first?.localizedName ?? bundleIdentifier
            applicationsByBundleID[bundleIdentifier] = ScopedApplication(
                bundleIdentifier: bundleIdentifier,
                name: name
            )
        }

        return AudioInputSnapshot(
            applications: applicationsByBundleID.values.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            },
            hasUnidentifiedApplication: hasUnidentifiedApplication
        )
    }

    private static func readProcessObjects() -> [AudioObjectID]? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        ) == noErr else { return nil }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var processObjects = [AudioObjectID](
            repeating: kAudioObjectUnknown,
            count: count
        )
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &processObjects
        ) == noErr else { return nil }
        return processObjects
    }

    private static func isRunningInput(_ processObject: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyIsRunningInput,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(
            processObject,
            &address,
            0,
            nil,
            &dataSize,
            &value
        ) == noErr && value != 0
    }

    private static func readBundleIdentifier(_ processObject: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyBundleID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: CFString?
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        let status = withUnsafeMutablePointer(to: &value) { pointer in
            AudioObjectGetPropertyData(
                processObject,
                &address,
                0,
                nil,
                &dataSize,
                pointer
            )
        }
        guard status == noErr, let value else { return nil }
        return value as String
    }
}
