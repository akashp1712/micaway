#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"

swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)"
DIST_PATH="$APP_ROOT/dist"
APP_PATH="$DIST_PATH/Hear Me Not.app"

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
cp "$BIN_PATH/HearMeNot" "$APP_PATH/Contents/MacOS/HearMeNot"
cp "$APP_ROOT/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
codesign --force --deep --sign - "$APP_PATH"

echo "Built: $APP_PATH"
