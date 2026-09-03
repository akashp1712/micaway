# MicAway product overview

Last updated: 2026-09-03

Current version: 0.5.2 developer preview

Official website: https://micaway.akashpanchal.com/

Source code: https://github.com/akashp1712/micaway

License: MIT

## What MicAway is

MicAway is a macOS menu-bar utility for people who keep a voice or dictation app open while working. It reads head direction from supported AirPods. After the user calibrates a forward position, MicAway mutes writable microphone inputs when the user turns away and restores only the inputs it muted when the user faces the Mac again.

MicAway does not capture audio, perform transcription, create an account, or send analytics.

## The problem

Continuous voice tools can mistake a side conversation for input. Keyboard shortcuts work, but they require the user to interrupt the conversation and remember the current mute state.

## Features

- AirPods head-direction gesture with dwell and hysteresis to reduce accidental state changes
- Low, Medium, and High turn-sensitivity presets
- Every App and Selected Apps operating modes
- Safety behavior that disables automatic muting when an unselected or unidentified app is using microphone input
- Master Turnaway Muting switch for carrying or repositioning a laptop
- Safe re-centering when automatic muting is resumed
- Local operation without an account, transcription, analytics, or a network service

## Requirements

- macOS 14 Sonoma or newer
- Apple silicon or Intel Mac
- AirPods with dynamic head tracking for turnaway gestures
- A physical or virtual input device that exposes a writable Core Audio mute property

Users should use the normal mute control in their voice or meeting app for deliberate muting. MicAway restores only input devices that it muted itself.

## Distribution

MicAway is free and open source under the MIT License. Version 0.5.2 is a universal developer preview. Its downloadable application is ad-hoc signed but is not Developer ID signed or notarized, so macOS may require first-launch approval.

## Limitations

- Some virtual microphones do not expose a writable mute state.
- Selected Apps works at the macOS application level, not at the browser-tab level.
- Head-motion availability depends on the AirPods model, connection state, and macOS behavior.
- MicAway is not a replacement for a meeting application's visible mute control when mute certainty is required.

## Independence

MicAway is an independent project and is not affiliated with or endorsed by Apple, OpenAI, Wispr Flow, or FluidVoice. Product names belong to their respective owners.
