# Contributing to MicAway

Thanks for helping make voice work less awkward.

## Useful contributions

- Test a voice app, Mac, macOS version, or AirPods model we have not covered.
- Reproduce and reduce connection, calibration, or microphone-restoration bugs.
- Improve accessibility, documentation, or the first-run experience.
- Propose a focused implementation with tests where the behavior can be isolated.

For compatibility results, use the compatibility issue form. Include the selected input device and whether MicAway muted and restored it correctly. Never include private dictated text, recordings, credentials, or logs you have not reviewed.

## Local setup

```bash
git clone https://github.com/akashp1712/micaway.git
cd micaway/apps/mac
swift test
./scripts/build-app.sh
```

To run the landing page:

```bash
corepack pnpm install
corepack pnpm dev:web
```

## Pull requests

Keep changes narrow, explain the user-visible behavior, and include the manual test you performed. New turnaway logic should include a unit test. UI changes should remain usable with keyboard navigation and reduced motion.

By contributing, you agree that your contribution may be distributed under the MIT License.
