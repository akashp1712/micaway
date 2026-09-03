# MicAway compatibility

Last updated: 2026-09-03

Current version: 0.5.1

## System compatibility

| Component | Support |
| --- | --- |
| macOS | macOS 14 Sonoma or newer |
| Mac processors | Apple silicon and Intel through a universal binary |
| Head tracking | AirPods models that support dynamic head tracking |
| Deliberate manual mute | Use the voice or meeting app's normal mute control |

Known head-tracking-capable families include AirPods Pro, AirPods 3 and 4, and AirPods Max. Availability can still depend on the specific generation, connection state, and macOS behavior.

## Voice applications

MicAway works at the macOS input-device layer rather than integrating with a voice app's private API. FluidVoice has been manually verified. ChatGPT Voice and Wispr Flow are candidates for community compatibility testing.

## Selected Apps behavior

Selected Apps mode uses Core Audio process information to identify applications currently consuming microphone input. Automatic turnaway muting is enabled only when every identified input-consuming application is on the user's selected list.

If a meeting app is using the microphone and is not selected, automatic muting stays inactive. If macOS reports an input consumer without an identifiable bundle, MicAway also stays inactive. This is a fail-open safety choice intended to avoid accidental muting in meetings.

App selection is application-wide. A browser is treated as one application; MicAway cannot distinguish a voice tab from a meeting tab in the same browser.

## Input-device limitation

A voice app must use an input device whose mute property macOS allows MicAway to write. Some virtual microphones do not expose that property and may require a future MicAway virtual-input mode.

Report a tested combination at https://github.com/akashp1712/micaway/issues/new?template=compatibility-report.yml without including private dictated text.
