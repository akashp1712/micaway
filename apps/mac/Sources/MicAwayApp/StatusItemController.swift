import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController {
    private let model: AppModel
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var cancellables = Set<AnyCancellable>()
    private var hotKey: GlobalHotKey?
    private var lastIcon: IconKey?

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
    }

    func invalidate() {
        hotKey?.invalidate()
        hotKey = nil
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
            return
        }
        showPopover()
    }

    /// Force the controls on screen regardless of whether the menu-bar icon is
    /// currently visible. On a notched/crowded bar or inside a full-screen app,
    /// the status item can be drawn to a hidden menu bar; re-launching MicAway
    /// (which fires applicationShouldHandleReopen) routes here so the user can
    /// always reach the UI.
    func showPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
    }
}
