#!/bin/bash
# Builds Brim in Release, ad-hoc signs it and packages a drag-to-install DMG.
#
# Usage:  scripts/make-dmg.sh [version]
#   version  defaults to the project's MARKETING_VERSION, e.g. 0.5.0
#
# Output: dist/Brim-<version>.dmg and dist/Brim-<version>.dmg.sha256
# Used by the release workflow, and handy for testing a release locally.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-$(xcodebuild -project Brim.xcodeproj -scheme Brim -showBuildSettings 2>/dev/null \
    | awk '$1 == "MARKETING_VERSION" { print $3; exit }')}"
BUILD_DIR="build"
OUT_DIR="dist"
APP="$BUILD_DIR/Build/Products/Release/Brim.app"
DMG="$OUT_DIR/Brim-$VERSION.dmg"

echo "==> Building Brim $VERSION"
rm -rf "$APP" "$OUT_DIR"
mkdir -p "$OUT_DIR"
xcodebuild \
    -project Brim.xcodeproj \
    -scheme Brim \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -destination 'generic/platform=macOS' \
    MARKETING_VERSION="$VERSION" \
    -quiet \
    build

echo "==> Signing (ad-hoc)"
# Apple silicon only runs signed code. Ad-hoc signing needs no Apple account;
# users still approve the first launch once in System Settings.
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

echo "==> Packaging $DMG"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "Brim" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null

shasum -a 256 "$DMG" | awk '{ print $1 }' > "$DMG.sha256"
echo "==> Done: $DMG"
echo "    SHA-256: $(cat "$DMG.sha256")"
