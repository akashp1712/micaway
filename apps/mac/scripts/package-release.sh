#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-0.1.0}"
ARCHIVE_NAME="MicAway-${VERSION}-universal.zip"
CHECKSUM_NAME="MicAway-${VERSION}-universal.sha256"

cd "$APP_ROOT"
./scripts/build-app.sh

rm -f "dist/$ARCHIVE_NAME" "dist/$CHECKSUM_NAME"
xattr -cr "dist/MicAway.app"
(
  cd dist
  /usr/bin/zip -qry -X "$ARCHIVE_NAME" "MicAway.app" -x "*.DS_Store" "*/._*"
  shasum -a 256 "$ARCHIVE_NAME" > "$CHECKSUM_NAME"
)

echo "Packaged: $APP_ROOT/dist/$ARCHIVE_NAME"
echo "Checksum: $APP_ROOT/dist/$CHECKSUM_NAME"
