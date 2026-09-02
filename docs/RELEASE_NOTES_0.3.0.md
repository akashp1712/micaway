# MicAway 0.3.0 — Developer preview

Turn your head. Mute the mic.

This preview is a **universal build** (Apple silicon + Intel) and adds
sensitivity control on top of the 0.1 foundation:

- universal binary — runs natively on Apple silicon (M1 through M4, all
  variants) and Intel Macs;
- **Turn sensitivity** control (Low / Medium / High) in the popover, so you
  set how far you can turn before the mic mutes;
- a tuned default (Medium): mute past ~45°, restore under ~28°, with dwell
  timing that ignores brief glances;
- **⌥⌘M** global manual mute, plus a menu-bar toggle;
- AirPods head-direction calibration with dwell and hysteresis;
- connection, disconnection, AirPods-swap, and app-restart recovery;
- muting across available writable macOS input devices, restoring only the
  devices MicAway muted;
- manually verified FluidVoice compatibility;
- an MIT-licensed Swift codebase.

## Download

Download `MicAway-0.3.0-universal.zip` and verify it with
`MicAway-0.3.0-universal.sha256`:

```bash
shasum -a 256 -c MicAway-0.3.0-universal.sha256
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
