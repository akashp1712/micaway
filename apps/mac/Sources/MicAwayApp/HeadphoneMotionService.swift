@preconcurrency import CoreMotion
import Foundation

@MainActor
final class HeadphoneMotionService: NSObject, CMHeadphoneMotionManagerDelegate {
    enum Status: Equatable {
        case looking
        case connected
        case unavailable(String)
    }

    var onYaw: ((Double) -> Void)?
    var onStatus: ((Status) -> Void)?

    private let manager = CMHeadphoneMotionManager()
    private var isRunning = false
    private var availabilityRetryTask: Task<Void, Never>?
    private var streamRecoveryTask: Task<Void, Never>?
    private var sampleWatchdogTask: Task<Void, Never>?
    private var streamGeneration = 0
    private var streamRestartAttempts = 0
    private var isMotionStreamRequested = false
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.akashpanchal.micaway.motion"
        queue.qualityOfService = .userInteractive
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    override init() {
        super.init()
        manager.delegate = self
    }

    func start() {
        guard !isRunning else {
            startUpdatesIfAvailable()
            return
        }

        isRunning = true
        guard motionAccessIsAllowed else { return }

        onStatus?(.looking)
        if !manager.isConnectionStatusActive {
            manager.startConnectionStatusUpdates()
        }
        startUpdatesIfAvailable()
    }

    func stop() {
        isRunning = false
        cancelRecoveryTasks()
        isMotionStreamRequested = false
        manager.stopDeviceMotionUpdates()
        if manager.isConnectionStatusActive {
            manager.stopConnectionStatusUpdates()
        }
    }

    func retry() {
        guard isRunning else {
            start()
            return
        }

        cancelRecoveryTasks()
        isMotionStreamRequested = false
        streamRestartAttempts = 0
        manager.stopDeviceMotionUpdates()
        onStatus?(.looking)
        startUpdatesIfAvailable()
    }

    nonisolated func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor [weak self] in
            self?.streamRestartAttempts = 0
            self?.startUpdatesIfAvailable()
        }
    }

    nonisolated func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor [weak self] in
            guard let self, self.isRunning else { return }
            self.cancelRecoveryTasks()
            self.isMotionStreamRequested = false
            self.manager.stopDeviceMotionUpdates()
            self.streamRestartAttempts = 0
            self.onStatus?(.looking)
        }
    }

    private func startUpdatesIfAvailable() {
        guard isRunning, motionAccessIsAllowed else { return }

        guard manager.isDeviceMotionAvailable else {
            onStatus?(.looking)
            scheduleAvailabilityRetry()
            return
        }

        availabilityRetryTask?.cancel()
        availabilityRetryTask = nil
        onStatus?(.connected)
        guard !manager.isDeviceMotionActive, !isMotionStreamRequested else { return }

        startMotionStream()
    }

    private func startMotionStream() {
        streamRecoveryTask?.cancel()
        streamRecoveryTask = nil
        streamGeneration += 1
        let generation = streamGeneration
        isMotionStreamRequested = true

        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            let yaw = motion?.attitude.yaw
            let message = error?.localizedDescription

            Task { @MainActor [weak self] in
                guard let self else { return }
                if let yaw {
                    self.streamRestartAttempts = 0
                    self.sampleWatchdogTask?.cancel()
                    self.sampleWatchdogTask = nil
                    self.onYaw?(yaw)
                } else if let message {
                    self.recoverMotionStream(after: message)
                }
            }
        }

        scheduleSampleWatchdog(for: generation)
    }

    private var motionAccessIsAllowed: Bool {
        switch CMHeadphoneMotionManager.authorizationStatus() {
        case .denied, .restricted:
            cancelRecoveryTasks()
            isMotionStreamRequested = false
            manager.stopDeviceMotionUpdates()
            onStatus?(.unavailable("Motion access is off in System Settings."))
            return false
        case .authorized, .notDetermined:
            return true
        @unknown default:
            onStatus?(.unavailable("Motion access is unavailable on this Mac."))
            return false
        }
    }

    private func scheduleAvailabilityRetry() {
        guard availabilityRetryTask == nil else { return }

        availabilityRetryTask = Task { @MainActor [weak self] in
            var attempts = 0
            while let self, self.isRunning, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                if self.manager.isDeviceMotionAvailable {
                    self.availabilityRetryTask = nil
                    self.startUpdatesIfAvailable()
                    return
                }

                attempts += 1
                if attempts == 5 {
                    self.onStatus?(.unavailable(
                        "No AirPods head motion is available. Put both compatible AirPods in your ears, make them the audio output, then retry."
                    ))
                }
            }
        }
    }

    private func scheduleSampleWatchdog(for generation: Int) {
        sampleWatchdogTask?.cancel()
        sampleWatchdogTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard
                let self,
                self.isRunning,
                !Task.isCancelled,
                self.streamGeneration == generation
            else { return }

            self.recoverMotionStream(after: "AirPods connected, but no head-motion samples arrived.")
        }
    }

    private func recoverMotionStream(after message: String) {
        guard isRunning, isMotionStreamRequested else { return }

        sampleWatchdogTask?.cancel()
        sampleWatchdogTask = nil
        isMotionStreamRequested = false
        manager.stopDeviceMotionUpdates()
        streamRestartAttempts += 1

        let attempts = streamRestartAttempts
        if attempts >= 3 {
            onStatus?(.unavailable("\(message) Retrying automatically."))
        }

        let delay = attempts >= 3 ? 5_000_000_000 : UInt64(attempts) * 500_000_000
        streamRecoveryTask?.cancel()
        streamRecoveryTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard let self, self.isRunning, !Task.isCancelled else { return }
            if attempts >= 3 {
                self.streamRestartAttempts = 0
            }
            self.startUpdatesIfAvailable()
        }
    }

    private func cancelRecoveryTasks() {
        availabilityRetryTask?.cancel()
        availabilityRetryTask = nil
        streamRecoveryTask?.cancel()
        streamRecoveryTask = nil
        sampleWatchdogTask?.cancel()
        sampleWatchdogTask = nil
    }
}
