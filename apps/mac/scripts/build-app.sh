#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"

DEPLOY_TARGET="14.0"
ARCHS=("arm64" "x86_64")
BUILD_DIR="$APP_ROOT/.build/direct"
DIST_PATH="$APP_ROOT/dist"
APP_PATH="$DIST_PATH/MicAway.app"

CORE_SRCS=(Sources/MicAwayCore/*.swift)
APP_SRCS=(Sources/MicAwayApp/*.swift)

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

THIN_BINS=()
for arch in "${ARCHS[@]}"; do
  target="${arch}-apple-macosx${DEPLOY_TARGET}"
  archdir="$BUILD_DIR/$arch"
  mkdir -p "$archdir"

  # 1) MicAwayCore as a module + object
  xcrun swiftc -O -wmo -target "$target" -parse-as-library \
    -module-name MicAwayCore \
    -emit-module -emit-module-path "$archdir/MicAwayCore.swiftmodule" \
    -emit-object -o "$archdir/MicAwayCore.o" \
    "${CORE_SRCS[@]}"

  # 2) MicAwayApp importing the core module
  xcrun swiftc -O -target "$target" -I "$archdir" \
    -framework AppKit -framework CoreAudio -framework CoreMotion \
    "$archdir/MicAwayCore.o" "${APP_SRCS[@]}" \
    -o "$archdir/MicAway"

  THIN_BINS+=("$archdir/MicAway")
done

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
lipo -create "${THIN_BINS[@]}" -output "$APP_PATH/Contents/MacOS/MicAway"
cp "$APP_ROOT/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$APP_ROOT/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP_PATH"

echo "Built: $APP_PATH"
lipo -info "$APP_PATH/Contents/MacOS/MicAway"
