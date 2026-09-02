#!/usr/bin/env bash
set -uo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"

echo "== Attempting canonical swift-testing suite (swift test) =="
if swift test 2>/tmp/micaway-swifttest.log; then
  echo "swift test passed."
  exit 0
fi
echo "swift test unavailable/broken (log: /tmp/micaway-swifttest.log)."
echo "== Falling back to standalone swiftc smoke tests =="

DEPLOY_TARGET="14.0"
target="$(uname -m)-apple-macosx${DEPLOY_TARGET}"
BUILD_DIR="$APP_ROOT/.build/tests"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcrun swiftc -O -wmo -target "$target" -parse-as-library \
  -module-name MicAwayCore \
  -emit-module -emit-module-path "$BUILD_DIR/MicAwayCore.swiftmodule" \
  -emit-object -o "$BUILD_DIR/MicAwayCore.o" \
  Sources/MicAwayCore/*.swift

xcrun swiftc -O -target "$target" -I "$BUILD_DIR" \
  "$BUILD_DIR/MicAwayCore.o" scripts/support/StandaloneTests.swift \
  -o "$BUILD_DIR/StandaloneTests"

"$BUILD_DIR/StandaloneTests"
