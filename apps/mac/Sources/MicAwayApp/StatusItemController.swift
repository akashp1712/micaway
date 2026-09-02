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
    private var lastSymbol: String?

    init(model: AppModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // A stable identity so the user can ⌘-drag the icon to a visible slot
        // (e.g. out from behind the notch on a crowded menu bar) and have macOS
        // remember that position across launches.
        statusItem.autosaveName = "com.akashpanchal.micaway.statusitem"

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(model: model)
        )

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
            model?.manualMuteEngaged.toggle()
        }
    }

    private func updateButtonImage() {
        guard let button = statusItem.button else { return }

        // The model publishes on every head-yaw sample; only touch AppKit when
        // the glyph actually changes to avoid rebuilding the image each tick.
        let symbol = model.menuBarSymbol
        if symbol != lastSymbol {
            lastSymbol = symbol
            if let image = NSImage(
                systemSymbolName: symbol,
                accessibilityDescription: model.statusTitle
            ) {
                image.isTemplate = true
                button.image = image
                button.title = ""
            } else {
                // Guarantee the item is never invisible if a symbol name is
                // unavailable on this macOS version.
                button.image = nil
                button.title = "Mic"
            }
        }
        button.setAccessibilityLabel(model.statusTitle)
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
}
