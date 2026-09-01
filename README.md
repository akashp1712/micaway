<p align="center">
  <img src="apps/web/public/brand/micaway-app-icon.png" alt="MicAway app icon" width="132" />
</p>

<h1 align="center">MicAway</h1>

<p align="center"><strong>Turn your head. Mute the mic.</strong></p>

<p align="center">
  A free, open-source macOS utility that uses AirPods head tracking to keep side conversations out of voice apps.
</p>

<p align="center">
  <a href="https://github.com/akashp1712/micaway/releases/latest"><strong>Download the developer preview</strong></a>
  ·
  <a href="apps/mac/README.md">How it works</a>
  ·
  <a href="https://github.com/akashp1712/micaway/issues/new?template=compatibility-report.yml">Report compatibility</a>
</p>

<p align="center">
  <img alt="macOS 14 or newer" src="https://img.shields.io/badge/macOS-14%2B-171714?style=flat-square" />
  <img alt="Apple silicon" src="https://img.shields.io/badge/Mac-Apple_silicon-171714?style=flat-square" />
  <img alt="Swift 5.10" src="https://img.shields.io/badge/Swift-5.10-F05138?style=flat-square" />
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-43A56D?style=flat-square" /></a>
</p>

<p align="center">
  <img src="apps/web/public/images/micaway-turnaway.png" alt="A developer wearing AirPods turning away from a Mac for a side conversation" width="920" />
</p>

> [!IMPORTANT]
> **Version 0.1 is an unsigned Apple-silicon developer preview.** It is free to download and audit, but macOS will ask you to approve the first launch. Signed and notarized distribution can come later; the source and behavior are available now.

## The problem

Voice-first work is fast—until “yes, I’ll be there in five” lands in the middle of your prompt.

MicAway turns attention into a physical microphone boundary:

- face your Mac to speak;
- turn toward someone nearby and your available input devices mute;
- face back and MicAway restores only the inputs it muted.

No wake word. No global shortcut. No audio processing.

## Voice-app compatibility

MicAway acts on writable macOS input devices, so it is not tied to one dictation app. A voice app must be using a physical input that macOS allows MicAway to mute.

| Voice app | Status | Use case |
| --- | --- | --- |
| **FluidVoice** | ✅ Manually verified | Keep local dictation clean while briefly speaking to someone nearby. |
| **Wispr Flow** | 🧪 Community test wanted | Prevent an aside from entering fast, system-wide dictation. |
| **ChatGPT Voice** | 🧪 Community test wanted | Pause your microphone naturally during a voice conversation. |

If you test another Mac, AirPods model, or voice app, open a [compatibility report](https://github.com/akashp1712/micaway/issues/new?template=compatibility-report.yml). Please never paste private dictated text into an issue.

## Install the preview

1. Download `MicAway-0.1.0-arm64.zip` from the [latest release](https://github.com/akashp1712/micaway/releases/latest).
2. Unzip it and move `MicAway.app` to **Applications**.
3. Control-click the app and choose **Open**. If macOS still blocks it, go to **System Settings → Privacy & Security** and choose **Open Anyway**.
4. Put compatible AirPods in both ears, launch MicAway, face your Mac, and select **Calibrate**.

MicAway lives in the menu bar. It requires macOS 14 or newer and a Mac with Apple silicon for the current binary.

## Privacy by construction

MicAway does not request microphone permission because it never listens to your microphone.

- no audio recording or transcription;
- no analytics or account;
- no network service;
- calibration stays on your Mac;
- the source is small enough to inspect.

It reads head direction from supported AirPods and changes the mute state of available input devices through macOS audio APIs.

## Build from source

Requirements: macOS 14+, Xcode Command Line Tools, and Swift 5.10 or newer.

```bash
git clone https://github.com/akashp1712/micaway.git
cd micaway/apps/mac
./scripts/build-app.sh
open "dist/MicAway.app"
```

Run the tests with:

```bash
cd apps/mac
swift test
```

Package the release archive and checksum with:

```bash
cd apps/mac
./scripts/package-release.sh 0.1.0
```

## Repository map

```text
apps/mac/   Swift menu-bar app, motion tracking, and tests
apps/web/   MicAway landing page
docs/       Product and engineering notes
```

## Known limits

- Compatible AirPods and Motion access are required for head tracking.
- The current downloadable build is Apple-silicon only and not notarized.
- A voice app using a non-mutable virtual microphone may need a future MicAway virtual-input mode.
- Headphone motion availability can vary by AirPods generation, connection state, and macOS behavior.

## Contributing

Bug reports, compatibility results, accessibility improvements, and focused pull requests are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md), and read [SECURITY.md](SECURITY.md) before reporting a vulnerability.

## License

MicAway is available under the [MIT License](LICENSE). © 2026 Akash Panchal.

MicAway is an independent open-source project and is not affiliated with or endorsed by Wispr Flow, FluidVoice, OpenAI, or Apple. Product names and logos belong to their respective owners.
