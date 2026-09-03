# MicAway for Mac

A tiny, open-source macOS menu-bar utility that uses AirPods head motion to decide whether speech is meant for the Mac.

## What works in this spike

- Streams yaw from compatible AirPods through `CMHeadphoneMotionManager`.
- Calibrates a forward, Mac-facing direction.
- Applies dwell plus hysteresis so quick glances do not flap the state.
- Shows `Listening` and `Not for your Mac` in a minimal menu-bar popover.
- Mutes every connected input device that exposes Core Audio's mute property, so voice apps can keep their own microphone selection.
- Restores only microphones that MicAway muted itself.
- Recovers from AirPods disconnects, reconnects, swaps, and app restarts.
- Can restrict automatic muting to selected microphone-using apps; an unselected or unidentified input app safely prevents automatic muting.
- Can pause turnaway muting and safely re-center when it is resumed.

Most physical Mac microphones expose a system mute switch. A voice app using a virtual or otherwise non-mutable input may still require a MicAway virtual microphone in a future release.

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

**Turn sensitivity:** choose Low / Medium / High in the popover to set how far
you can turn before the mic mutes. Medium (the default) mutes past ~45° and
restores under ~28°; Low tolerates a bigger turn, High reacts to a smaller one.

**App scope:** choose **Every app** or **Selected apps**. To add an app, bring
it forward and choose **Apps → Add _App Name_** from the MicAway popover. In selected
mode, automatic muting is active only when every identified app consuming mic
input is selected.

**Moving around:** switch **Turnaway muting** off before carrying or moving the
Mac. Switching it back on safely re-centers to the current position.

Use the voice or meeting app's normal mute control for deliberate manual mute.
MicAway restores only inputs it muted itself and does not undo a mute that was
already active elsewhere.

Grant Motion access when macOS asks. Put in your AirPods, open the menu-bar item, face the Mac, and choose **Calibrate**.

The local bundle is ad-hoc signed for testing. A public binary release should be signed with Developer ID and notarized.

## Voice app compatibility check

1. Select a microphone in the voice app and begin dictating.
2. Face the Mac and confirm speech is captured.
3. Turn past the calibrated boundary and keep speaking for three seconds.
4. Confirm no words from the turned-away interval appear.
5. Face the Mac again and confirm dictation resumes.

Repeat after changing the voice app's microphone, swapping AirPods, disconnecting and reconnecting them, and relaunching either app. FluidVoice has been verified manually; Wispr Flow still needs a hardware test.

## Test

```bash
cd apps/mac
./scripts/test.sh
```
Runs the swift-testing suite via SwiftPM when available, otherwise a standalone
`swiftc`-compiled smoke test of the intent engine and mute logic.

The intent engine is kept free of AppKit and Core Motion so its thresholds, timing, and angle wrapping can be tested deterministically.
