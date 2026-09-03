#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$APP_ROOT/../.." && pwd)"
OUT="$REPO_ROOT/apps/web/public/images/menu"
BIN="$APP_ROOT/dist/MicAway.app/Contents/MacOS/MicAway"

if [[ ! -x "$BIN" ]]; then
  echo "Build the app first: ./scripts/build-app.sh" >&2
  exit 1
fi

mkdir -p "$OUT"
MICAWAY_SNAPSHOT_DIR="$OUT" "$BIN"
ls -la "$OUT"
