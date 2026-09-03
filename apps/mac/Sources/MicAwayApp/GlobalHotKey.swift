import AppKit
import Carbon.HIToolbox

/// A single system-wide hotkey via Carbon `RegisterEventHotKey`.
/// Needs no Accessibility entitlement and no third-party dependency.
@MainActor
final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let handler: () -> Void
    private let id: UInt32

    private static var registry: [UInt32: GlobalHotKey] = [:]
    private static var nextID: UInt32 = 1
    private static let signature: OSType = 0x4D494341 // 'MICA'

    /// ⌥⌘M — pause or resume MicAway (turnaway muting), not microphone mute.
    static func micAwayToggle(handler: @escaping () -> Void) -> GlobalHotKey {
        GlobalHotKey(
            keyCode: UInt32(kVK_ANSI_M),
            modifiers: UInt32(optionKey | cmdKey),
            handler: handler
        )
    }

    init(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        self.handler = handler
        self.id = GlobalHotKey.nextID
        GlobalHotKey.nextID += 1
        GlobalHotKey.registry[id] = self
        installHandler()
        register(keyCode: keyCode, modifiers: modifiers)
    }

    private func installHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                let targetID = hkID.id
                MainActor.assumeIsolated {
                    GlobalHotKey.registry[targetID]?.handler()
                }
                return noErr
            },
            1,
            &spec,
            nil,
            &eventHandlerRef
        )
    }

    private func register(keyCode: UInt32, modifiers: UInt32) {
        let hkID = EventHotKeyID(signature: GlobalHotKey.signature, id: id)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hkID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func invalidate() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        hotKeyRef = nil
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
        eventHandlerRef = nil
        GlobalHotKey.registry[id] = nil
    }
}
