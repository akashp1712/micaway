# MicAway for Mac

A tiny, open-source macOS menu-bar utility that uses AirPods head motion to mute your call when you turn away and bring the mic back when you face the Mac.

## What works in this spike

- Streams yaw from compatible AirPods through `CMHeadphoneMotionManager`.
- Calibrates a forward, Mac-facing direction.
- Applies dwell plus hysteresis so quick glances do not flap the state.
- Shows `On for this call` with `Live — you’re facing the Mac` or `Muted — you’re turned away` in a minimal menu-bar popover. `Inactive here` appears only when no allowed app has the mic.
- Mutes every connected input device that exposes Core Audio's mute property, so call apps can keep their own microphone selection. It does not press the call app's mute button, so the in-app mic icon may stay open while the room hears silence.
- Restores only microphones that MicAway muted itself.
- Mutes only while an app is using the microphone, so a call never starts on a mic MicAway muted while idle.
- Never holds a mute without live motion: if AirPods disconnect or samples are older than 1.5s (`MuteResolver.maxSampleAgeSeconds`), the mic is restored. A 0.5s watchdog catches streams that stop without a disconnect, and mutes again if samples return while you are still turned away.
- Tracks muted inputs by device UID in a persisted ledger (`MutedInputLedger`), so a microphone that AirPods re-add under a new ID, or one left muted by a crash, is still unmuted. Each unmute is read back and retried until it holds.
- Shows **No head motion** when Motion access is off or AirPods send no samples, instead of a misleading **Ready**.
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

**Turn sensitivity:** the Advanced slider sets how far you can turn before the
mic mutes (25–65°, default 45°). Drag toward High for a smaller turn; the
readout is the mute-past angle.

**App scope:** expand **Advanced**, then choose **Every app** or **Selected apps**
(the default). **Allowed apps** is seeded on first launch with Zoom, Microsoft
Teams, Slack, FaceTime, Discord, Webex, Google Chrome, Safari, Arc, and Firefox.
To add another app, bring it forward and choose **Allowed apps → Add _App Name_**.
In selected mode, automatic muting is active only when every identified app
consuming mic input is allowed. **Never mute during** starts empty; it holds
calls you want left alone. The seed and the one-time migration from the earlier
seed live in `Sources/MicAwayCore/ApplicationListDefaults.swift`.

**Moving around:** switch **Turnaway muting** off (`⌥⌘M`) before carrying or moving the
Mac. Switching it back on safely re-centers to the current position.

Use the call app's normal mute control for deliberate manual mute.
MicAway restores only inputs it muted itself and does not undo a mute that was
already active elsewhere.

Grant Motion access when macOS asks. Put in your AirPods, open the menu-bar item, face the Mac, and choose **Calibrate**.

Motion access is tied to the ad-hoc signature, so every rebuild can lose it. If the menu shows **No head motion** after reinstalling, turn MicAway on in **System Settings → Privacy & Security → Motion & Fitness**, or run `tccutil reset Motion com.akashpanchal.micaway` and relaunch to get the prompt again.

The local bundle is ad-hoc signed for testing. A public binary release should be signed with Developer ID and notarized.

## Call compatibility check

1. Join a test call (Zoom, Teams, Slack, FaceTime, or Meet in a browser) with a second device listening.
2. Face the Mac and confirm the other side hears you.
3. Turn past the calibrated boundary and keep speaking for three seconds.
4. Confirm the other side hears silence. Note whether the call app's own mic icon changed.
5. Face the Mac again and confirm the other side hears you again.

The same check works for dictation apps: confirm no words from the turned-away interval appear.

Repeat after changing the voice app's microphone, swapping AirPods, disconnecting and reconnecting them, and relaunching either app. FluidVoice has been verified manually; Wispr Flow still needs a hardware test.

## Test

```bash
cd apps/mac
./scripts/test.sh
```
Runs the swift-testing suite via SwiftPM when available, otherwise a standalone
`swiftc`-compiled smoke test of the intent engine and mute logic.

The intent engine is kept free of AppKit and Core Motion so its thresholds, timing, and angle wrapping can be tested deterministically.
