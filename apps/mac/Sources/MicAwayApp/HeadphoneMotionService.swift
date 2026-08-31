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
        guard CMHeadphoneMotionManager.authorizationStatus() != .denied else {
            onStatus?(.unavailable("Motion access is off in System Settings."))
            return
        }

        onStatus?(.looking)
        startUpdatesIfAvailable()
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }

    nonisolated func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor [weak self] in
            self?.startUpdatesIfAvailable()
        }
    }

    nonisolated func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor [weak self] in
            self?.manager.stopDeviceMotionUpdates()
            self?.onStatus?(.looking)
        }
    }

    private func startUpdatesIfAvailable() {
        guard manager.isDeviceMotionAvailable else {
            onStatus?(.looking)
            return
        }

        manager.stopDeviceMotionUpdates()
        onStatus?(.connected)
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            let yaw = motion?.attitude.yaw
            let message = error?.localizedDescription

            Task { @MainActor [weak self] in
                guard let self else { return }
                if let yaw {
                    self.onYaw?(yaw)
                } else if let message {
                    self.onStatus?(.unavailable(message))
                }
            }
        }
    }
}
