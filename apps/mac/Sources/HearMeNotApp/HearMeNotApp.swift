import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

@main
struct HearMeNotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("Hear Me Not", systemImage: model.menuBarSymbol) {
            MenuBarContentView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
