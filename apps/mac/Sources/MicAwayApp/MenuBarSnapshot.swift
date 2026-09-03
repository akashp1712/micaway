import AppKit
import MicAwayCore
import SwiftUI

/// Renders the live menu SwiftUI into PNGs for the landing page.
/// Invoked when `MICAWAY_SNAPSHOT_DIR` is set; never runs in normal launches.
@MainActor
enum MenuBarSnapshotRenderer {
    private static var windows: [NSWindow] = []

    static func write(to directory: URL, completion: @escaping () -> Void) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        NSApplication.shared.appearance = NSAppearance(named: .aqua)

        let jobs: [(String, AppModel, Bool)] = [
            (
                "calibrate",
                AppModel(
                    snapshotIntent: .needsCalibration,
                    yawDegrees: 0,
                    message: "Motion connected. Face your Mac and calibrate."
                ),
                false
            ),
            (
                "listening",
                AppModel(
                    snapshotIntent: .listening,
                    yawDegrees: 0,
                    message: "Forward set. The boundary is ready."
                ),
                false
            ),
            (
                "away",
                AppModel(
                    snapshotIntent: .turnaway,
                    yawDegrees: 42,
                    message: "Forward set. The boundary is ready."
                ),
                false
            ),
            (
                "paused",
                AppModel(
                    snapshotIntent: .listening,
                    yawDegrees: 8,
                    turnawayEnabled: false,
                    message: "Turnaway muting is off."
                ),
                false
            ),
            (
                "advanced",
                AppModel(
                    snapshotIntent: .listening,
                    yawDegrees: 0,
                    message: "Forward set. The boundary is ready."
                ),
                true
            ),
        ]

        capture(jobs: jobs, directory: directory, index: 0, completion: completion)
    }

    private static func capture(
        jobs: [(String, AppModel, Bool)],
        directory: URL,
        index: Int,
        completion: @escaping () -> Void
    ) {
        guard index < jobs.count else {
            windows.removeAll()
            completion()
            return
        }

        let (name, model, advanced) = jobs[index]
        let popoverShape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let root = MenuBarContentView(model: model, advancedExpanded: advanced)
            .environment(\.snapshotCapture, true)
            .preferredColorScheme(.light)
            .frame(width: 300)
            .background(Color(nsColor: NSColor(calibratedWhite: 0.96, alpha: 1)))
            .clipShape(popoverShape)
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.10), radius: 2, y: 1)
            .shadow(color: Color.black.opacity(0.18), radius: 18, y: 8)
            .padding(28)

        let hosting = NSHostingController(rootView: root)
        hosting.sizingOptions = .preferredContentSize

        let window = NSWindow(
            contentRect: NSRect(x: -5000, y: -5000, width: 300, height: 480),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)
        window.backgroundColor = .clear
        window.contentViewController = hosting
        hosting.view.wantsLayer = true
        hosting.view.layer?.isOpaque = false
        hosting.view.layer?.backgroundColor = NSColor.clear.cgColor
        window.orderFrontRegardless()
        windows.append(window)

          DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            let fitted = hosting.view.fittingSize
            if fitted.width > 1, fitted.height > 1 {
                hosting.view.setFrameSize(fitted)
                window.setContentSize(fitted)
            }
            hosting.view.layoutSubtreeIfNeeded()
            hosting.view.displayIfNeeded()

            let bounds = hosting.view.bounds
            let scale: CGFloat = 2
            if let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(bounds.width * scale),
                pixelsHigh: Int(bounds.height * scale),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) {
                bitmap.size = bounds.size
                hosting.view.cacheDisplay(in: bounds, to: bitmap)
                if let data = bitmap.representation(using: .png, properties: [:]) {
                    try? data.write(to: directory.appendingPathComponent("\(name).png"))
                }
            }

            window.orderOut(nil)
            capture(jobs: jobs, directory: directory, index: index + 1, completion: completion)
        }
    }
}
