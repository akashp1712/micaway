# Install MicAway 0.5.0

Official release page: https://github.com/akashp1712/micaway/releases/latest

## Download

1. Download `MicAway-0.5.0-universal.zip` from the official latest release.
2. Optionally download `MicAway-0.5.0-universal.sha256` and verify it with `shasum -a 256 -c MicAway-0.5.0-universal.sha256`.
3. Unzip the archive and move `MicAway.app` to Applications.

## First launch

Version 0.5.0 is ad-hoc signed but is not Developer ID signed or notarized. If macOS blocks it, open System Settings, choose Privacy & Security, scroll to Security, select Open Anyway, and confirm Open.

If macOS still refuses the official release, run:

```bash
xattr -cr "/Applications/MicAway.app"
open "/Applications/MicAway.app"
```

Run that command only for `MicAway.app` downloaded from the official MicAway GitHub release. Do not use a wildcard or a broader Applications or Downloads path.

## Setup

1. Put compatible AirPods in both ears.
2. Allow Motion access if macOS requests it.
3. Face the Mac and choose Calibrate.
4. Choose Every app or Selected apps under Use MicAway in.
5. In Selected Apps mode, bring a voice app forward, open MicAway, and choose Apps, then Add App Name.

The Turnaway Muting switch pauses automatic behavior. When it is switched back on, MicAway safely re-centers to the user's current position. Use the voice or meeting app's normal mute control for deliberate muting; MicAway does not undo a mute it did not create.
