#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"

swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)"
DIST_PATH="$APP_ROOT/dist"
APP_PATH="$DIST_PATH/MicAway.app"

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"
cp "$BIN_PATH/MicAway" "$APP_PATH/Contents/MacOS/MicAway"
cp "$APP_ROOT/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$APP_ROOT/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP_PATH"

echo "Built: $APP_PATH"
