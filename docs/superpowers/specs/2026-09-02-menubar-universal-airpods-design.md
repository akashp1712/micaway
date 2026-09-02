# MicAway: menu-bar reliability, universal build, AirPods reach

Date: 2026-09-02
Status: Approved for planning

## Problem

On a notched 16" MacBook Pro (Mac14,6, macOS 26.6.2, Apple Silicon) with an
external ultrawide as the main display, MicAway launches and runs but its
menu-bar icon never appears. Investigation found two independent root causes:

1. **Menu-bar presence (the user-visible symptom).** The app renders its
   menu-bar item with SwiftUI `MenuBarExtra`. When the system menu bar
   overflows behind the notch, `MenuBarExtra` items are silently dropped
   rather than moved to an overflow region. The process is alive (no crash,
   no crash logs) but shows nothing. `MenuBarExtra` is also historically
   flaky across macOS releases and offers no control over placement.

2. **Build reproducibility (blocks local build/verify).** The installed
   Command Line Tools (26.5.0) ship a `PackageDescription.swiftmodule`
   interface that is out of sync with `libPackageDescription.dylib`
   (interface advertises a `swiftLanguageVersions: [SwiftVersion]` /
   `SwiftLanguageMode.v6` API the dylib does not export). Every `swift build`
   fails at the manifest-link step regardless of `swift-tools-version`; a
   fresh `swift package init` template fails identically. No full Xcode is
   installed to fall back to. The app *sources* compile fine via direct
   `swiftc`.

Additional goals from the requester:
- Cover all Apple Silicon (M1/M1 Pro/Max/Ultra, M2, M3, M4) **and** Intel.
- Be resilient to future macOS/toolchain versions.
- Support all *applicable* AirPods (the motion-capable models) and degrade
  gracefully for everything else.

## Constraints and non-negotiables

- **macOS 14.0 is the hard floor.** `CMHeadphoneMotionManager` (the only API
  for AirPods head-yaw on macOS) is macOS 14+. Chip is irrelevant to this.
- **No new third-party dependencies.** Match the existing dependency-free
  Swift style.
- The pure decision logic (`TurnawayEngine`) stays free of AppKit/CoreMotion
  so it remains deterministically testable.

## Design

### 1. Menu-bar presence: NSStatusItem, AppDelegate-owned

Replace the `MenuBarExtra` scene with an explicit, AppDelegate-managed
`NSStatusItem`.

- `AppDelegate` creates one status item via
  `NSStatusBar.system.statusItem(withLength: .variableLength)` in
  `applicationDidFinishLaunching` and retains it in a stored property.
  (A dropped reference is itself a classic "icon disappears" bug — the
  strong reference is load-bearing.)
- The button image is an SF Symbol built with
  `NSImage(systemSymbolName:accessibilityDescription:)`, with
  `image.isTemplate = true` so it renders correctly in light/dark menu bars
  and under Reduce Transparency. The symbol reflects the same three states
  as today (`needsCalibration` / `listening` / `turnaway`), plus the manual
  states (see §2).
- The AppDelegate subscribes to `AppModel` (Combine `objectWillChange` or a
  dedicated publisher) and updates the button image + accessibility label on
  each state change, on the main actor.
- Clicking the button toggles an `NSPopover` (`behavior = .transient`) whose
  `contentViewController` is
  `NSHostingController(rootView: MenuBarContentView(model:))`. **The existing
  SwiftUI popover UI is reused unchanged** aside from wiring.
- The SwiftUI `App` body becomes `Settings { EmptyView() }` (invisible under
  `LSUIElement`). All menu-bar lifecycle lives in the AppDelegate. The
  existing redundant `setActivationPolicy(.accessory)` call is kept (harmless,
  and correct alongside `LSUIElement`).

Rationale: `NSStatusItem` is the stable, battle-tested API. It reliably
creates the item, renders on the active display's menu bar, and participates
in standard status-item overflow handling instead of being silently dropped.

### 2. AirPods reach and graceful fallback

- Keep `HeadphoneMotionService` / `CMHeadphoneMotionManager` as the motion
  source. Capability = `isDeviceMotionAvailable` becoming true after connect
  (covers AirPods Pro 1/2, AirPods 3/4, AirPods Max). No model allow-list —
  the availability flag is the correct, forward-compatible signal.
- Clarify status copy so "head tracking unavailable on this device" vs
  "waiting for AirPods" vs "motion permission off" are unambiguous. Reuse the
  existing `Status` enum; refine messages only.
- **Manual fallback (new).** A "Mute mic" control that works with no motion at
  all, driven by the existing `InputMuteController`. Introduce an explicit
  manual-mute state in `AppModel` distinct from the motion-driven gate so the
  two don't fight. When head tracking is unavailable, the popover surfaces the
  manual toggle prominently.
- **Global hotkey (new).** A fixed default **⌥⌘M** toggles the manual mute
  hands-free, implemented with Carbon `RegisterEventHotKey`
  (`EventHotKeyRef` + a Carbon event handler). This needs no accessibility
  entitlement and no external dependency. The hotkey is registered on launch
  and unregistered on quit. No configurable-hotkey UI (YAGNI).

### 3. Build and packaging: universal, no SwiftPM

- Rewrite `scripts/build-app.sh` to **not invoke SwiftPM**:
  1. Compile `MicAwayCore` to a `.swiftmodule` + object with `xcrun swiftc`
     for `arm64-apple-macosx14.0` and `x86_64-apple-macosx14.0`.
  2. Compile `MicAwayApp` (importing the core module via `-I`) for each arch,
     linking AppKit / CoreAudio / CoreMotion / Carbon.
  3. `lipo -create` the two per-arch binaries into one universal binary.
  4. Assemble the `.app` bundle (MacOS/, Resources/, Info.plist, icon) and
     ad-hoc `codesign`.
  This is decoupled from `swift-tools-version` / ManifestAPI, so it survives
  toolchain drift and works on the broken CLT.
- `scripts/package-release.sh`: emit `MicAway-<ver>-universal.zip` (+
  `.sha256`) instead of `-arm64`.
- Add `scripts/test.sh`: compile and run the `TurnawayEngine` XCTest via
  direct `xcrun swiftc` linking `XCTest`, so tests run despite broken SwiftPM.
- Keep `Package.swift` for IDE/editor and toolchain-healthy machines. Update
  `apps/mac/README.md` to document the direct-`swiftc` scripts as the primary
  path and note the CLT-mismatch symptom + workaround.

### 4. Future macOS support

- `LSMinimumSystemVersion` stays `14.0`; deployment target `macosx14.0` for
  both arches. No deprecated APIs introduced (`NSStatusItem`, `NSPopover`,
  `NSHostingController`, Carbon hotkeys are all long-stable). Availability
  guards where a newer symbol is used.

## Components and boundaries

- `TurnawayEngine` (MicAwayCore) — unchanged pure logic; still unit-tested.
- `HeadphoneMotionService` — unchanged responsibilities; refined status copy.
- `InputMuteController` — unchanged; now also driven by the manual gate.
- `AppModel` — gains an explicit manual-mute state and its interaction with
  the motion-driven gate; publishes menu-bar symbol + accessibility label.
- `StatusItemController` (new, in MicAwayApp) — owns the `NSStatusItem`,
  the `NSPopover`, image updates, and the global hotkey registration. Single
  clear purpose; testable seams kept minimal (AppKit-bound, verified by
  running the app).
- `MenuBarContentView` — reused; add the manual-mute affordance and clearer
  unavailable-state messaging.

## Testing and verification

- `TurnawayEngine` thresholds/timing/angle-wrapping: existing XCTest via
  `scripts/test.sh`.
- Build the universal `.app` locally, launch it, and confirm the
  `NSStatusItem` is present (verifiable because the item is now app-owned).
- Confirm `lipo -info` reports both `arm64` and `x86_64`.
- Manual checklist in README updated for the manual-mute toggle and ⌥⌘M
  hotkey, plus the existing turn-away voice-app compatibility steps.

## Out of scope (YAGNI)

- Configurable-hotkey UI or a Settings window.
- Developer-ID signing / notarization pipeline changes.
- Lowering the macOS floor below 14 for a manual-only mode.
- Any new third-party dependency.
