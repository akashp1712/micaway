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

Most physical Mac microphones expose a system mute switch. A voice app using a virtual or otherwise non-mutable input may still require a MicAway virtual microphone in a future release.

## Run on a Mac

Requirements: macOS 14+, Xcode Command Line Tools, and AirPods with dynamic head tracking.

```bash
cd apps/mac
./scripts/build-app.sh
open "dist/MicAway.app"
```

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
swift test
```

The intent engine is kept free of AppKit and Core Motion so its thresholds, timing, and angle wrapping can be tested deterministically.
