import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let directory = ProcessInfo.processInfo.environment["MICAWAY_SNAPSHOT_DIR"] {
            MenuBarSnapshotRenderer.write(to: URL(fileURLWithPath: directory)) {
                NSApplication.shared.terminate(nil)
            }
            return
        }

        NSApplication.shared.setActivationPolicy(.accessory)
        let model = AppModel()
        self.model = model
        statusItemController = StatusItemController(model: model)
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusItemController?.invalidate()
        model?.prepareForTermination()
    }

    // Re-launching MicAway while it is already running (double-click in
    // /Applications or Spotlight) reveals the controls — the reliable way to
    // reach the UI when the menu-bar icon is hidden behind the notch or a
    // full-screen Space.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusItemController?.showPopover()
        return true
    }
}

@main
struct MicAwayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
