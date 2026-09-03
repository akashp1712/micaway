# MicAway roadmap

MicAway’s job is a **physical boundary for continuous voice**: face the Mac to speak, turn away and the aside stays out. It does that by reading AirPods head direction and changing microphone mute state locally. It does not listen.

This file is intent, not a schedule. Items move when someone is actually building them. Open an [idea issue](https://github.com/akashp1712/micaway/issues/new?template=idea.yml) to argue for, against, or refine anything here.

## The constraint that shapes everything

Software MicAway stays interesting because it **never needs the audio**. That rules out on-Mac voice activity detection, “only capture when you are speaking,” and camera-based gaze as default features. Those ideas can still exist — they belong in a different product, with a different permission story.

## Next for the Mac app

These extend the current wedge without changing what MicAway is.

### Workspace geometry — ultrawide and multi-monitor

**Same problem, two setups.** Today “forward” is a single yaw cone around one calibrated pose. Looking at a side monitor, or at the far edge of an ultrawide, is a legitimate Mac-facing pose that the current model can treat as a turn-away.

What we want instead is the **angular width of the workspace** from the chair: left edge of the leftmost display to right edge of the rightmost display. Ultrawide is a wide single span. Multi-monitor is the same span with bezels in the middle.

Likely shape:

1. A calibration that captures left and right bounds, not only center.
2. Optional mapping from `NSScreen` layout so adding/removing a display can reshape the cone without a full recalibrate.
3. Sensitivity presets become a fallback, not the only way to tolerate a wide desk.

This is the highest-leverage software change. It is also the one current users will hit first as they sit down at a real desk.

### Ship trust

- Developer ID signature and notarization, so the first launch is not a security obstacle course.
- A virtual input device for voice apps whose microphone cannot be muted through Core Audio. Already listed under known limits; it is the compatibility unlock after geometry.

### Gesture depth

Yaw is “turn to a colleague.” **Pitch** is “look down at a phone or across a desk.” A small downward look is a common aside that should not require a 45° head turn. This stays inside the AirPods motion story.

## A hardware MicAway — research, not the next app release

A desk microphone that **only captures when you are speaking near it**, and stays quiet when you are across the room, is the same thesis in another form: *not every word is for the machine*.

It is **not a feature of `MicAway.app`**. It is a different product.

| Why it is interesting | Why it is a different company |
| --- | --- |
| Works without AirPods | Hardware has inventory, certification, returns, and support |
| Complements head-direction: proximity instead of pose | “Only capture when near” is audio DSP. The Mac app’s privacy claim is that it never hears you |
| A physical object you can sell | Competes with existing dynamic/proximity mics and with software noise gating |

If this is pursued, the privacy-preserving version is **gating on the mic**, so the Mac only ever receives already-bounded audio. Putting VAD on the Mac would break the current product’s contract.

Treat this as a separate exploration: research notes, not issues on the Mac app milestone.

## Also worth considering

- **More IMU headphones.** AirPods are the motion source we have. Any headset that exposes a stable head-pose stream is in scope for the same mute logic.
- **Clamshell and carry.** Pause already exists. Detecting lid-close, display sleep, or a large reference-frame jump and auto-pausing would remove a class of false mutes without a new concept.
- **Clearer first-run.** Calibrate is the whole product. The first session should make left/right workspace bounds obvious, especially once geometry lands.

## Not on the roadmap

- Transcription, accounts, or a network service.
- Replacing a meeting app’s visible mute control.
- Camera gaze as a default, on-Mac “attention” sensor. It is a different permission and a different trust model.
- Browser-tab scoping. Selected Apps is process-level; a Chrome meeting tab vs a Chrome dictation tab is not something Core Audio will tell us.

## How to use this file

Comment on an existing idea via a GitHub issue. A good argument is a desk setup, a failed gesture, or a compatibility hole — not a feature name. Compatibility results still go through the [compatibility report](https://github.com/akashp1712/micaway/issues/new?template=compatibility-report.yml).
