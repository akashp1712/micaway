# MicAway Menu-bar / Universal Build / AirPods Reach — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make MicAway's menu-bar icon reliably appear on all Macs, build a universal binary that survives toolchain drift, and support all motion-capable AirPods with a manual-mute + hotkey fallback.

**Architecture:** Replace SwiftUI `MenuBarExtra` with an AppDelegate-owned `NSStatusItem` + `NSPopover` that reuses the existing SwiftUI popover view. Add a pure `MuteResolver` in `MicAwayCore` as the single source of truth for the mute decision, driven by both the motion gate and a new manual gate. Ship via direct-`swiftc` build scripts (no SwiftPM) producing an arm64+x86_64 universal binary.

**Tech Stack:** Swift 5/6, AppKit, SwiftUI (`NSHostingController`), CoreMotion (`CMHeadphoneMotionManager`), CoreAudio, Carbon (`RegisterEventHotKey`), swift-testing. No third-party dependencies.

**Spec:** `docs/superpowers/specs/2026-09-02-menubar-universal-airpods-design.md`

## Global Constraints

- **macOS floor: 14.0** — `CMHeadphoneMotionManager` requires it. `LSMinimumSystemVersion` = `14.0`; all compile targets use `-target <arch>-apple-macosx14.0`.
- **Universal binary: `arm64` + `x86_64`** — covers all Apple Silicon (M1/M1 Pro/Max/Ultra, M2, M3, M4) and Intel.
- **No third-party dependencies.** Dependency-free Swift only.
- **`TurnawayEngine` and `MuteResolver` stay free of AppKit / CoreMotion / CoreAudio** so they remain deterministically unit-testable.
- **Build is SwiftPM-free** (direct `xcrun swiftc` + `lipo`); `Package.swift` is retained only for IDEs / healthy toolchains.
- **Ad-hoc codesign** (`codesign --force --deep --sign -`); no notarization changes.
- **Fixed global hotkey: ⌥⌘M** (Option+Command+M). No configurable-hotkey UI.
- All working dirs are relative to `apps/mac/` unless stated. Run scripts from `apps/mac/`.

---

### Task 1: SwiftPM-free universal build + standalone test harness

**Files:**
- Modify: `apps/mac/scripts/build-app.sh` (full rewrite)
- Modify: `apps/mac/scripts/package-release.sh`
- Create: `apps/mac/scripts/test.sh`
- Create: `apps/mac/scripts/support/StandaloneTests.swift`

**Interfaces:**
- Consumes: existing `Sources/MicAwayCore/*.swift`, `Sources/MicAwayApp/*.swift`, `Resources/Info.plist`, `Resources/AppIcon.icns`.
- Produces: `./scripts/build-app.sh` → `dist/MicAway.app` (universal); `./scripts/test.sh` → runs smoke tests, exits nonzero on failure. Later tasks add `-framework Carbon` reliance (already included here) and extend `StandaloneTests.swift`.

- [ ] **Step 1: Rewrite `scripts/build-app.sh`** to compile per-arch with `swiftc` and `lipo` them together.

```bash
#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"

DEPLOY_TARGET="14.0"
ARCHS=("arm64" "x86_64")
BUILD_DIR="$APP_ROOT/.build/direct"
DIST_PATH="$APP_ROOT/dist"
APP_PATH="$DIST_PATH/MicAway.app"

CORE_SRCS=(Sources/MicAwayCore/*.swift)
APP_SRCS=(Sources/MicAwayApp/*.swift)

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

THIN_BINS=()
for arch in "${ARCHS[@]}"; do
  target="${arch}-apple-macosx${DEPLOY_TARGET}"
  archdir="$BUILD_DIR/$arch"
  mkdir -p "$archdir"

  # 1) MicAwayCore as a module + object
  xcrun swiftc -O -target "$target" -parse-as-library \
    -module-name MicAwayCore \
    -emit-module -emit-module-path "$archdir/MicAwayCore.swiftmodule" \
    -emit-object -o "$archdir/MicAwayCore.o" \
    "${CORE_SRCS[@]}"

  # 2) MicAwayApp importing the core module
  xcrun swiftc -O -target "$target" -I "$archdir" \
    -framework AppKit -framework CoreAudio -framework CoreMotion -framework Carbon \
    "$archdir/MicAwayCore.o" "${APP_SRCS[@]}" \
    -o "$archdir/MicAway"

  THIN_BINS+=("$archdir/MicAway")
done

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
lipo -create "${THIN_BINS[@]}" -output "$APP_PATH/Contents/MacOS/MicAway"
cp "$APP_ROOT/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$APP_ROOT/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP_PATH"

echo "Built: $APP_PATH"
lipo -info "$APP_PATH/Contents/MacOS/MicAway"
```

- [ ] **Step 2: Create `scripts/support/StandaloneTests.swift`** — a dependency-free smoke runner (engine only for now; MuteResolver added in Task 2).

```swift
import Foundation
import MicAwayCore

var failures = 0

func check(_ condition: Bool, _ label: String) {
    if condition {
        print("ok   - \(label)")
    } else {
        failures += 1
        print("FAIL - \(label)")
    }
}

func degrees(_ value: Double) -> Double { value * .pi / 180 }

// TurnawayEngine smoke checks (mirror the canonical swift-testing suite).
var engine = TurnawayEngine()
check(engine.update(yawRadians: 0.4, timestamp: 0).state == .needsCalibration,
      "engine requires calibration first")

engine.calibrate(yawRadians: 0)
check(engine.update(yawRadians: degrees(32), timestamp: 0).state == .listening,
      "engine stays listening before enter dwell")
check(engine.update(yawRadians: degrees(32), timestamp: 0.25).state == .turnaway,
      "engine enters turnaway after enter dwell")
check(engine.update(yawRadians: degrees(10), timestamp: 0.85).state == .listening,
      "engine exits turnaway after exit dwell")

if failures == 0 {
    print("ALL PASS")
    exit(0)
} else {
    print("\(failures) FAILURE(S)")
    exit(1)
}
```

- [ ] **Step 3: Create `scripts/test.sh`** — try SwiftPM, fall back to the standalone smoke runner.

```bash
#!/usr/bin/env bash
set -uo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"

echo "== Attempting canonical swift-testing suite (swift test) =="
if swift test 2>/tmp/micaway-swifttest.log; then
  echo "swift test passed."
  exit 0
fi
echo "swift test unavailable/broken (log: /tmp/micaway-swifttest.log)."
echo "== Falling back to standalone swiftc smoke tests =="

DEPLOY_TARGET="14.0"
target="$(uname -m)-apple-macosx${DEPLOY_TARGET}"
BUILD_DIR="$APP_ROOT/.build/tests"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcrun swiftc -O -target "$target" -parse-as-library \
  -module-name MicAwayCore \
  -emit-module -emit-module-path "$BUILD_DIR/MicAwayCore.swiftmodule" \
  -emit-object -o "$BUILD_DIR/MicAwayCore.o" \
  Sources/MicAwayCore/*.swift

xcrun swiftc -O -target "$target" -I "$BUILD_DIR" \
  "$BUILD_DIR/MicAwayCore.o" scripts/support/StandaloneTests.swift \
  -o "$BUILD_DIR/StandaloneTests"

"$BUILD_DIR/StandaloneTests"
```

- [ ] **Step 4: Update `scripts/package-release.sh`** for a universal artifact name.

Replace the archive/checksum name lines:
```bash
ARCHIVE_NAME="MicAway-${VERSION}-universal.zip"
CHECKSUM_NAME="MicAway-${VERSION}-universal.sha256"
```
(Leave the rest of the script unchanged.)

- [ ] **Step 5: Make scripts executable and run the test harness**

```bash
cd apps/mac
chmod +x scripts/build-app.sh scripts/test.sh scripts/package-release.sh
./scripts/test.sh
```
Expected: SwiftPM path fails on the broken CLT, fallback runs, prints `ALL PASS`, exit 0.

- [ ] **Step 6: Run the build and verify the universal binary**

```bash
cd apps/mac
./scripts/build-app.sh
lipo -info dist/MicAway.app/Contents/MacOS/MicAway
```
Expected: `Built: .../dist/MicAway.app` and `Architectures in the fat file: ... arm64 x86_64`.

- [ ] **Step 7: Commit**

```bash
git add apps/mac/scripts/build-app.sh apps/mac/scripts/test.sh \
        apps/mac/scripts/package-release.sh apps/mac/scripts/support/StandaloneTests.swift
git commit -m "build: SwiftPM-free universal build + standalone test harness"
```

---

### Task 2: `MuteResolver` — pure mute-decision logic (TDD)

**Files:**
- Create: `apps/mac/Sources/MicAwayCore/MuteResolver.swift`
- Create: `apps/mac/Tests/MicAwayCoreTests/MuteResolverTests.swift`
- Modify: `apps/mac/scripts/support/StandaloneTests.swift`

**Interfaces:**
- Consumes: `IntentState` (from `MicAwayCore/TurnawayEngine.swift`).
- Produces: `MuteResolver.shouldMute(manualMuteEngaged: Bool, guardEnabled: Bool, microphoneGateEnabled: Bool, intentState: IntentState) -> Bool` — consumed by `AppModel` in Task 4.

- [ ] **Step 1: Add failing checks to `scripts/support/StandaloneTests.swift`** (insert immediately before the final `if failures == 0` block).

```swift
// MuteResolver checks
check(MuteResolver.shouldMute(manualMuteEngaged: true, guardEnabled: false,
                              microphoneGateEnabled: false, intentState: .listening),
      "manual mute forces mute regardless of gates")
check(MuteResolver.shouldMute(manualMuteEngaged: false, guardEnabled: true,
                              microphoneGateEnabled: true, intentState: .turnaway),
      "turnaway mutes when guard + gate on")
check(!MuteResolver.shouldMute(manualMuteEngaged: false, guardEnabled: true,
                               microphoneGateEnabled: true, intentState: .listening),
      "listening does not mute")
check(!MuteResolver.shouldMute(manualMuteEngaged: false, guardEnabled: false,
                               microphoneGateEnabled: true, intentState: .turnaway),
      "guard off suppresses motion mute")
check(!MuteResolver.shouldMute(manualMuteEngaged: false, guardEnabled: true,
                               microphoneGateEnabled: false, intentState: .turnaway),
      "gate off suppresses motion mute")
```

- [ ] **Step 2: Run to verify it fails to compile/link** (symbol not defined)

```bash
cd apps/mac && ./scripts/test.sh
```
Expected: fallback compile fails with `cannot find 'MuteResolver' in scope`.

- [ ] **Step 3: Create `Sources/MicAwayCore/MuteResolver.swift`**

```swift
/// Single source of truth for whether microphone input should be muted.
///
/// Manual mute always wins. Otherwise the motion gate mutes only when the
/// turnaway guard and the microphone gate are both enabled and the wearer has
/// turned away from the Mac.
public enum MuteResolver {
    public static func shouldMute(
        manualMuteEngaged: Bool,
        guardEnabled: Bool,
        microphoneGateEnabled: Bool,
        intentState: IntentState
    ) -> Bool {
        if manualMuteEngaged { return true }
        return guardEnabled && microphoneGateEnabled && intentState == .turnaway
    }
}
```

- [ ] **Step 4: Run to verify smoke tests pass**

```bash
cd apps/mac && ./scripts/test.sh
```
Expected: `ALL PASS`, exit 0.

- [ ] **Step 5: Add the canonical swift-testing suite** `Tests/MicAwayCoreTests/MuteResolverTests.swift`

```swift
import Testing
@testable import MicAwayCore

struct MuteResolverTests {
    @Test func manualMuteForcesMute() {
        #expect(MuteResolver.shouldMute(
            manualMuteEngaged: true, guardEnabled: false,
            microphoneGateEnabled: false, intentState: .listening))
    }

    @Test func turnawayMutesWhenGuardAndGateOn() {
        #expect(MuteResolver.shouldMute(
            manualMuteEngaged: false, guardEnabled: true,
            microphoneGateEnabled: true, intentState: .turnaway))
    }

    @Test func listeningDoesNotMute() {
        #expect(!MuteResolver.shouldMute(
            manualMuteEngaged: false, guardEnabled: true,
            microphoneGateEnabled: true, intentState: .listening))
    }

    @Test func guardOffSuppressesMotionMute() {
        #expect(!MuteResolver.shouldMute(
            manualMuteEngaged: false, guardEnabled: false,
            microphoneGateEnabled: true, intentState: .turnaway))
    }

    @Test func gateOffSuppressesMotionMute() {
        #expect(!MuteResolver.shouldMute(
            manualMuteEngaged: false, guardEnabled: true,
            microphoneGateEnabled: false, intentState: .turnaway))
    }
}
```

- [ ] **Step 6: Commit**

```bash
git add apps/mac/Sources/MicAwayCore/MuteResolver.swift \
        apps/mac/Tests/MicAwayCoreTests/MuteResolverTests.swift \
        apps/mac/scripts/support/StandaloneTests.swift
git commit -m "feat(core): add MuteResolver as single source of mute decision"
```

---

### Task 3: NSStatusItem menu-bar controller + App scene swap

**Files:**
- Create: `apps/mac/Sources/MicAwayApp/StatusItemController.swift`
- Modify: `apps/mac/Sources/MicAwayApp/MicAwayApp.swift`

**Interfaces:**
- Consumes: `AppModel` (existing: `menuBarSymbol: String`, `statusTitle: String`, `objectWillChange`), `MenuBarContentView(model:)`.
- Produces: `StatusItemController(model: AppModel)` retaining an `NSStatusItem` + `NSPopover`; exposes `var hotKey` slot used in Task 5. `AppDelegate` now owns the `AppModel` and the controller.

- [ ] **Step 1: Create `Sources/MicAwayApp/StatusItemController.swift`**

```swift
import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController {
    private let model: AppModel
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var cancellables = Set<AnyCancellable>()

    init(model: AppModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

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
    }

    private func updateButtonImage() {
        guard let button = statusItem.button else { return }
        let image = NSImage(
            systemSymbolName: model.menuBarSymbol,
            accessibilityDescription: model.statusTitle
        )
        image?.isTemplate = true
        button.image = image
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
```

- [ ] **Step 2: Rewrite `Sources/MicAwayApp/MicAwayApp.swift`** to drop `MenuBarExtra` and own the status item in the delegate.

```swift
import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        let model = AppModel()
        self.model = model
        statusItemController = StatusItemController(model: model)
    }

    func applicationWillTerminate(_ notification: Notification) {
        model?.prepareForTermination()
    }
}

@main
struct MicAwayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
```

Note: `prepareForTermination()` is added to `AppModel` in Task 4. Until then this references a method that does not yet exist — build verification for the icon happens after Task 4. To keep Task 3 independently buildable, temporarily add a stub in this step and replace in Task 4:
- In `MicAwayApp.swift` Task 3, replace `model?.prepareForTermination()` with `model?.quit()` is wrong (recurses). Instead, for Task 3, use:
```swift
    func applicationWillTerminate(_ notification: Notification) {
        // Replaced with model.prepareForTermination() in Task 4.
    }
```

- [ ] **Step 3: Build to verify it compiles and the icon appears**

```bash
cd apps/mac && ./scripts/build-app.sh && open dist/MicAway.app
sleep 2
pgrep -lf "MicAway.app/Contents/MacOS/MicAway" && echo "running"
```
Expected: compiles, app runs, and a MicAway icon is now present in the menu bar (click it → the existing popover opens). Stop it afterward: `pkill -f "MicAway.app/Contents/MacOS/MicAway"`.

- [ ] **Step 4: Commit**

```bash
git add apps/mac/Sources/MicAwayApp/StatusItemController.swift \
        apps/mac/Sources/MicAwayApp/MicAwayApp.swift
git commit -m "fix(menubar): own NSStatusItem in AppDelegate instead of MenuBarExtra"
```

---

### Task 4: Manual-mute state in AppModel + popover controls

**Files:**
- Modify: `apps/mac/Sources/MicAwayApp/AppModel.swift`
- Modify: `apps/mac/Sources/MicAwayApp/MenuBarContentView.swift`

**Interfaces:**
- Consumes: `MuteResolver.shouldMute(...)` (Task 2), `InputMuteController` (existing: `canMuteInput()`, `muteForTurnaway()`, `restoreIfNeeded()`).
- Produces on `AppModel`: `@Published var manualMuteEngaged: Bool`, `var manualMuteAvailable: Bool`, `func prepareForTermination()`, and `menuBarSymbol` extended for the manual state (consumed by `StatusItemController` and `GlobalHotKey` in Task 5).

- [ ] **Step 1: Edit `AppModel.swift` — add manual state and centralize the mute decision.**

Add the published property near `microphoneGateEnabled`:
```swift
    @Published var manualMuteEngaged = false {
        didSet {
            guard manualMuteEngaged != oldValue else { return }
            applyMuteState()
        }
    }
```

Add availability alongside `microphoneGateAvailable`:
```swift
    var manualMuteAvailable: Bool { microphone.canMuteInput() }
```

Extend `menuBarSymbol` so manual mute is visible in the menu bar:
```swift
    var menuBarSymbol: String {
        if manualMuteEngaged { return "mic.slash.fill" }
        switch intentState {
        case .needsCalibration: "waveform.badge.exclamationmark"
        case .listening: "waveform.circle.fill"
        case .turnaway: "waveform.slash"
        }
    }
```

Replace the body of `synchronizeMicrophoneGate()` and `microphoneGateEnabledChanged()` and add `applyMuteState()` / `prepareForTermination()`. Concretely:

Replace:
```swift
    private func microphoneGateEnabledChanged() {
        if microphoneGateEnabled {
            synchronizeMicrophoneGate()
        } else {
            try? microphone.restoreIfNeeded()
        }
    }

    private func synchronizeMicrophoneGate() {
        guard microphoneGateEnabled else { return }

        do {
            if guardEnabled && intentState == .turnaway {
                try microphone.muteForTurnaway()
            } else {
                try microphone.restoreIfNeeded()
            }
        } catch {
            microphoneGateEnabled = false
            message = error.localizedDescription
        }
    }
```
with:
```swift
    private func microphoneGateEnabledChanged() {
        applyMuteState()
    }

    private func applyMuteState() {
        let shouldMute = MuteResolver.shouldMute(
            manualMuteEngaged: manualMuteEngaged,
            guardEnabled: guardEnabled,
            microphoneGateEnabled: microphoneGateEnabled,
            intentState: intentState
        )
        do {
            if shouldMute {
                try microphone.muteForTurnaway()
            } else {
                try microphone.restoreIfNeeded()
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func prepareForTermination() {
        motion.stop()
        try? microphone.restoreIfNeeded()
    }
```

Update the two remaining callers of the removed `synchronizeMicrophoneGate()`:
- In `apply(_:)`, change `synchronizeMicrophoneGate()` → `applyMuteState()`.
- In `guardEnabledChanged()`, change `synchronizeMicrophoneGate()` → `applyMuteState()`.

Update `quit()` to reuse the shared teardown:
```swift
    func quit() {
        prepareForTermination()
        NSApplication.shared.terminate(nil)
    }
```

- [ ] **Step 2: Restore the real `applicationWillTerminate` body** in `MicAwayApp.swift` (from the Task 3 stub):
```swift
    func applicationWillTerminate(_ notification: Notification) {
        model?.prepareForTermination()
    }
```

- [ ] **Step 3: Edit `MenuBarContentView.swift`** — add a manual-mute toggle and hotkey hint.

After the existing "Mute mic when turned away" toggle block, insert:
```swift
            Toggle("Mute mic now (⌥⌘M)", isOn: $model.manualMuteEngaged)
                .toggleStyle(.switch)
                .disabled(!model.manualMuteAvailable)
                .padding(.top, 10)
```

- [ ] **Step 4: Build and run to verify manual mute + menu-bar symbol change**

```bash
cd apps/mac && ./scripts/build-app.sh && open dist/MicAway.app
```
Expected: compiles; toggling "Mute mic now" flips the menu-bar icon to `mic.slash.fill` and mutes the default input (verify in System Settings → Sound → Input, or a voice app). Stop it: `pkill -f "MicAway.app/Contents/MacOS/MicAway"`.

- [ ] **Step 5: Run tests (regression)**

```bash
cd apps/mac && ./scripts/test.sh
```
Expected: `ALL PASS`.

- [ ] **Step 6: Commit**

```bash
git add apps/mac/Sources/MicAwayApp/AppModel.swift \
        apps/mac/Sources/MicAwayApp/MenuBarContentView.swift \
        apps/mac/Sources/MicAwayApp/MicAwayApp.swift
git commit -m "feat: manual mute gate driven by MuteResolver + popover control"
```

---

### Task 5: Global hotkey (⌥⌘M) toggling manual mute

**Files:**
- Create: `apps/mac/Sources/MicAwayApp/GlobalHotKey.swift`
- Modify: `apps/mac/Sources/MicAwayApp/StatusItemController.swift`

**Interfaces:**
- Consumes: `AppModel.manualMuteEngaged` (Task 4).
- Produces: `GlobalHotKey.micAwayToggle(handler: @escaping () -> Void) -> GlobalHotKey` and `GlobalHotKey.invalidate()`.

- [ ] **Step 1: Create `Sources/MicAwayApp/GlobalHotKey.swift`**

```swift
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

    /// ⌥⌘M — the fixed MicAway manual-mute toggle.
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
        // Closure captures nothing → convertible to a C function pointer.
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
```

- [ ] **Step 2: Wire the hotkey into `StatusItemController`.**

Add a stored property:
```swift
    private var hotKey: GlobalHotKey?
```
At the end of `init(model:)` add:
```swift
        hotKey = GlobalHotKey.micAwayToggle { [weak model] in
            model?.manualMuteEngaged.toggle()
        }
```

- [ ] **Step 3: Build and verify the hotkey toggles mute globally**

```bash
cd apps/mac && ./scripts/build-app.sh && open dist/MicAway.app
```
Expected: compiles; pressing **⌥⌘M** while any app is focused flips the menu-bar icon between `mic.slash.fill` and the current state icon, muting/unmuting the input. Stop it: `pkill -f "MicAway.app/Contents/MacOS/MicAway"`.

- [ ] **Step 4: Commit**

```bash
git add apps/mac/Sources/MicAwayApp/GlobalHotKey.swift \
        apps/mac/Sources/MicAwayApp/StatusItemController.swift
git commit -m "feat: global ⌥⌘M hotkey to toggle manual mute (Carbon, no deps)"
```

---

### Task 6: Version bump, docs, and final verification

**Files:**
- Modify: `apps/mac/Resources/Info.plist`
- Modify: `apps/mac/README.md`

**Interfaces:** none (docs + metadata).

- [ ] **Step 1: Bump version in `Resources/Info.plist`**
- `CFBundleShortVersionString` → `0.2.0`
- `CFBundleVersion` → `2`

- [ ] **Step 2: Update `apps/mac/README.md`** — replace the "Run on a Mac" and "Test" sections to reflect the SwiftPM-free scripts, universal binary, the ⌥⌘M manual-mute hotkey, and the CLT-mismatch note.

Add under requirements:
```markdown
## Build & run

Requirements: macOS 14+, Xcode Command Line Tools. AirPods with dynamic head
tracking (AirPods Pro 1/2, AirPods 3/4, AirPods Max) enable turn-away muting;
without them you can still mute manually.

```bash
cd apps/mac
./scripts/build-app.sh      # universal arm64 + x86_64 .app in dist/
open dist/MicAway.app
```

The build compiles directly with `swiftc` and `lipo` (no SwiftPM), so it works
even when a Command Line Tools update leaves `swift build` broken with
`Invalid manifest ... PackageDescription.Package.__allocating_init`. If you
have a healthy toolchain or full Xcode, `swift build` / `swift test` also work.

**Manual mute:** toggle it from the menu-bar popover or press **⌥⌘M** anywhere.

## Test

```bash
cd apps/mac
./scripts/test.sh
```
Runs the swift-testing suite via SwiftPM when available, otherwise a standalone
`swiftc`-compiled smoke test of the intent engine and mute logic.
```

- [ ] **Step 3: Final full verification**

```bash
cd apps/mac
./scripts/test.sh
./scripts/build-app.sh
lipo -info dist/MicAway.app/Contents/MacOS/MicAway
codesign --verify --strict dist/MicAway.app && echo "codesign ok"
open dist/MicAway.app && sleep 2
pgrep -lf "MicAway.app/Contents/MacOS/MicAway" && echo "running with menu-bar icon"
pkill -f "MicAway.app/Contents/MacOS/MicAway"
```
Expected: tests pass; fat file lists `arm64 x86_64`; codesign verifies; app runs with a visible menu-bar icon.

- [ ] **Step 4: Commit**

```bash
git add apps/mac/Resources/Info.plist apps/mac/README.md
git commit -m "docs: universal build, hotkey, CLT workaround; bump to 0.2.0"
```

---

## Self-Review

**Spec coverage:**
- §1 Menu-bar NSStatusItem → Task 3. ✓
- §2 AirPods capability messaging + manual gate + ⌥⌘M hotkey → Tasks 4 & 5; capability detection already lives in `HeadphoneMotionService` (status copy refinements folded into Task 4's popover/messaging via existing `model.message`). ✓
- §3 Universal no-SwiftPM build, package rename, `test.sh`, `Package.swift` retained → Task 1; README note → Task 6. ✓
- §4 Future macOS support / floor 14.0 → Global Constraints + per-arch `-target ...macosx14.0`; version bump Task 6. ✓
- `MuteResolver` single source of truth → Task 2, consumed in Task 4. ✓

**Placeholder scan:** No "TBD"/"handle edge cases"/"similar to Task N". The one forward reference (`prepareForTermination()` used in Task 3) is explicitly stubbed in Task 3 and completed in Task 4. ✓

**Type consistency:** `MuteResolver.shouldMute(manualMuteEngaged:guardEnabled:microphoneGateEnabled:intentState:)` identical in Tasks 2, 4, and StandaloneTests. `menuBarSymbol`/`statusTitle`/`objectWillChange` match `AppModel`. `GlobalHotKey.micAwayToggle(handler:)` defined Task 5, used Task 5. `manualMuteEngaged` / `manualMuteAvailable` / `prepareForTermination()` defined Task 4, used Tasks 3–5. ✓
