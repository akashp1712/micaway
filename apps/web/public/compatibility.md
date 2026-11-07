# MicAway compatibility

Last updated: 2026-11-07

Current version: 0.5.4

## System compatibility

| Component | Support |
| --- | --- |
| macOS | macOS 14 Sonoma or newer |
| Mac processors | Apple silicon and Intel through a universal binary |
| Head tracking | AirPods models that support dynamic head tracking |
| Deliberate manual mute | Use the call or voice app's normal mute control |

Known head-tracking-capable families include AirPods Pro, AirPods 3 and 4, and AirPods Max. Availability can still depend on the specific generation, connection state, and macOS behavior.

## Call and voice applications

MicAway works at the macOS input-device layer rather than integrating with an app's private API. Allowed apps is seeded with Zoom, Microsoft Teams, Slack, FaceTime, Discord, Webex, Google Chrome, Safari, Arc, and Firefox, so Google Meet in a browser works without setup. MicAway mutes the input device and does not press the call app's mute button, so the in-app mic icon may stay open while the room hears silence.

Dictation apps can be added through Allowed apps. FluidVoice has been manually verified. ChatGPT Voice and Wispr Flow are candidates for community compatibility testing.

## Selected Apps behavior

Selected Apps mode uses Core Audio process information to identify applications currently consuming microphone input. Automatic turnaway muting is enabled only when every identified input-consuming application is on the user's selected list.

If an app that is not allowed is also using the microphone, automatic muting stays off. If macOS reports an input consumer without an identifiable bundle, MicAway also stays off. This fail-open choice avoids muting an app the user did not choose. Never mute during, empty by default, lists calls the user wants left alone in every mode.

App selection is application-wide. A browser is treated as one application; MicAway cannot distinguish one tab from another in the same browser.

## Input-device limitation

A voice app must use an input device whose mute property macOS allows MicAway to write. Some virtual microphones do not expose that property and may require a future MicAway virtual-input mode.

Report a tested combination at https://github.com/akashp1712/micaway/issues/new?template=compatibility-report.yml without including private dictated text.
