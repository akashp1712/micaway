# Hear Me Not for Mac

A tiny macOS menu-bar utility that uses AirPods head motion to decide whether speech is meant for the Mac.

## What works in this spike

- Streams yaw from compatible AirPods through `CMHeadphoneMotionManager`.
- Calibrates a forward, Mac-facing direction.
- Applies dwell plus hysteresis so quick glances do not flap the state.
- Shows `Listening` and `Not for your Mac` in a minimal menu-bar popover.
- Can mute the default input device when that device exposes Core Audio's mute property. This is opt-in and off by default.
- Restores only a mute that Hear Me Not applied itself.

The motion path is the product validation. Universal app compatibility will later require a signed virtual microphone; the prototype does not fake that capability.

## Run on a Mac

Requirements: macOS 14+, Xcode Command Line Tools, and AirPods with dynamic head tracking.

```bash
cd apps/mac
./scripts/build-app.sh
open "dist/Hear Me Not.app"
```

Grant Motion access when macOS asks. Put in your AirPods, open the menu-bar item, face the Mac, and choose **Calibrate**.

The local bundle is ad-hoc signed for testing. Developer ID signing, notarization, Sparkle updates, and the virtual microphone belong after the AirPods behavior passes the hardware test.

## Test

```bash
cd apps/mac
swift test
```

The intent engine is kept free of AppKit and Core Motion so its thresholds, timing, and angle wrapping can be tested deterministically.
