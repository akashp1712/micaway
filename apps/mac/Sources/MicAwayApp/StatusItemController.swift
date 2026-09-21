import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let model: AppModel
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var cancellables = Set<AnyCancellable>()
    private var hotKey: GlobalHotKey?
    private var lastIcon: IconKey?
    private var resignObserver: NSObjectProtocol?
    private var clickMonitor: Any?

    private struct IconKey: Equatable {
        var status: MenuBarStatus
        var appearance: String
    }

    init(model: AppModel) {
        self.model = model
        // Square length keeps the status button bounds stable when the glyph
        // changes (pause vs waveform). Variable length shifts the popover
        // anchor by a few pixels and makes the panel look like it tilts.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        // A stable identity so the user can ⌘-drag the icon to a visible slot
        // (e.g. out from behind the notch on a crowded menu bar) and have macOS
        // remember that position across launches.
        statusItem.autosaveName = "com.akashpanchal.micaway.statusitem"

        let hostingController = NSHostingController(
            rootView: MenuBarContentView(model: model)
        )
        hostingController.sizingOptions = .preferredContentSize

        popover = NSPopover()
        popover.behavior = .transient
        // Size jumps from expanding Advanced must not be interpolated — SwiftUI
        // and NSPopover animating the same frame produces flicker.
        popover.animates = false
        popover.contentViewController = hostingController

        super.init()

        popover.delegate = self

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        updateButtonImage()

        // objectWillChange fires before the value changes; hopping to the next
        // main-runloop tick guarantees we read the updated model state.
        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateButtonImage() }
            .store(in: &cancellables)

        hotKey = GlobalHotKey.micAwayToggle { [weak model] in
            model?.turnawayEnabled.toggle()
        }

        // Close when the app stops being active — i.e. the user clicked into
        // another window, the desktop, or another app. Combined with the
        // .transient behavior this is the whole dismissal story; no event
        // monitor is needed (an earlier global monitor made the popover close
        // on hover). Hovering never resigns active, so this never misfires.
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.popover.performClose(nil) }
        }
    }

    func invalidate() {
        hotKey?.invalidate()
        hotKey = nil
        if let resignObserver {
            NotificationCenter.default.removeObserver(resignObserver)
            self.resignObserver = nil
        }
        removeClickMonitor()
    }

    /// Closes the popover on a genuine click into any *other* app — including
    /// another menu-bar item, whose modal menu tracking never resigns our
    /// active state, so `didResignActive` alone misses it. Global monitors only
    /// see events routed to other apps (never our own popover or status button)
    /// and only mouse-*down* — hover produces no such event, so this cannot
    /// cause the earlier hover-dismissal. Installed while shown, torn down in
    /// popoverDidClose.
    private func installClickMonitor() {
        guard clickMonitor == nil else { return }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown]
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.popover.performClose(nil) }
        }
    }

    private func removeClickMonitor() {
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
    }

    private func updateButtonImage() {
        guard let button = statusItem.button else { return }
        let appearance = button.effectiveAppearance
        let key = IconKey(
            status: model.menuBarStatus,
            appearance: appearance.name.rawValue
        )
        if key != lastIcon {
            lastIcon = key
            button.image = makeIcon(status: key.status, appearance: appearance)
            button.title = ""
        }
        button.setAccessibilityLabel(model.statusTitle)
    }

    private func makeIcon(status: MenuBarStatus, appearance: NSAppearance) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            appearance.performAsCurrentDrawingAppearance {
                Self.drawWaveform(in: rect)
                Self.drawDot(Self.dotColor(for: status), in: rect, appearance: appearance)
            }
            return true
        }
        image.isTemplate = false
        return image
    }

    private static func drawWaveform(in rect: NSRect) {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        guard let symbol = NSImage(
            systemSymbolName: "waveform.circle.fill",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(config) else { return }

        let iconRect = NSRect(x: 0, y: 1.5, width: 15.5, height: 15.5)
        symbol.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1)
        NSColor.labelColor.setFill()
        iconRect.fill(using: .sourceIn)
    }

    private static func drawDot(_ color: NSColor, in rect: NSRect, appearance: NSAppearance) {
        let dot = NSRect(x: 12.2, y: 0.6, width: 5.4, height: 5.4)
        let ring = dot.insetBy(dx: -1, dy: -1)
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        (isDark ? NSColor.black : NSColor.white).withAlphaComponent(0.92).setFill()
        NSBezierPath(ovalIn: ring).fill()
        color.setFill()
        NSBezierPath(ovalIn: dot).fill()
    }

    private static func dotColor(for status: MenuBarStatus) -> NSColor {
        switch status {
        case .listening:
            return NSColor(srgbRed: 0.18, green: 0.62, blue: 0.38, alpha: 1)
        case .turnaway:
            return NSColor(srgbRed: 0.72, green: 0.72, blue: 0.68, alpha: 1)
        case .paused, .inactive:
            return NSColor.systemGray
        case .needsCalibration:
            return NSColor.systemOrange
        }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    /// Presents the panel. Activating the app and making the popover key is what
    /// makes the accent-colored controls (the switch) render in color rather
    /// than the desaturated inactive-window state, lets ⌘R/⌘Q work, and makes
    /// the .transient dismissal reliable for an agent app. Also the reopen path:
    /// re-launching MicAway fires applicationShouldHandleReopen, which routes
    /// here so the UI is always reachable even behind a notch.
    func showPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        popover.contentViewController?.view.window?.makeKey()
        installClickMonitor()
    }
}

extension StatusItemController: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        removeClickMonitor()
    }
}
