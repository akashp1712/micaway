# MicAway

**Look away. Mic away.**

MicAway is an AirPods-aware microphone guard for macOS. It calibrates the direction of your Mac, watches relative head yaw locally, and pauses voice input when your attention turns toward someone else.

## Monorepo

```text
apps/web   Minimal product landing page
apps/mac   Native Swift menu-bar prototype
packages   Shared web design system and configuration
docs       Product and shipping notes
```

## Web

```bash
pnpm install
pnpm dev:web
pnpm build
```

## Mac prototype

Requires macOS 14+, Xcode Command Line Tools, and compatible AirPods with dynamic head tracking.

```bash
cd apps/mac
swift test
./scripts/build-app.sh
open "dist/MicAway.app"
```

The current hardware spike can mute the default input only when that device exposes Core Audio's mute property. Universal compatibility will require a signed virtual microphone later.

## Privacy

Motion processing stays on the Mac. The prototype does not record, store, or transcribe audio.
