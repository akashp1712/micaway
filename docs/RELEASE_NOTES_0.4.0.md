# MicAway 0.4.0 — Developer preview

Turn your head. Mute the mic. Now without false mutes on calls.

This release fixes a bug where MicAway could mute the microphone during
Google Meet, Slack, and similar calls **while you were still facing the
screen**.

## Fixed

- **No more phantom mutes when a call grabs the mic.** AirPods switch
  Bluetooth profile the moment a call starts using their microphone, which
  restarts the head-motion stream with a fresh yaw reference frame. MicAway
  now re-anchors "forward" to your current head position on that restart
  instead of reading the origin jump as a 60°+ turn-away. If a re-center
  happens you'll briefly see *"Head reference re-centered after an AirPods
  reconnect."* in the popover.

The re-anchor fails safe: if a reconnect lands while you happen to be turned
away, it re-centers rather than falsely muting, and self-heals on your next
Calibrate.

## Also in the 0.3 line (carried forward)

- universal binary — Apple silicon (M1–M4, all variants) and Intel;
- **Turn sensitivity** control (Low / Medium / High) with a tuned Medium
  default (mute past ~45°, restore under ~28°);
- **⌥⌘M** global manual mute, plus a menu-bar toggle;
- AirPods head-direction calibration with dwell and hysteresis;
- connection, disconnection, AirPods-swap, and app-restart recovery;
- muting across available writable macOS input devices, restoring only the
  devices MicAway muted;
- an MIT-licensed Swift codebase.

## Download

Download `MicAway-0.4.0-universal.zip` and verify it with
`MicAway-0.4.0-universal.sha256`:

```bash
shasum -a 256 -c MicAway-0.4.0-universal.sha256
```

This is an ad-hoc-signed build (not yet Developer ID signed or notarized).
On first launch, Control-click MicAway and choose **Open**. If macOS still
blocks it, use **System Settings → Privacy & Security → Open Anyway**.

Requires macOS 14 (Sonoma) or newer, and compatible AirPods with head
tracking for turn-away muting (AirPods Pro 1/2, AirPods 3/4, AirPods Max).
Without them you can still mute manually with ⌥⌘M.

## Please test

FluidVoice has been manually verified. Wispr Flow, ChatGPT Voice, additional
AirPods generations, and more Mac models need community reports.
