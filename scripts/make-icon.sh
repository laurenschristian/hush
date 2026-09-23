#!/bin/sh
# Compiles assets/Hush.icon (Icon Composer) into Resources/ and renders icon.png for the README.
# Needs Xcode 26+, so the output is committed and CI does not run this.
set -e
cd "$(dirname "$0")/.."
TMP=$(mktemp -d)
xcrun actool assets/Hush.icon --compile "$TMP" --app-icon Hush --platform macosx \
  --minimum-deployment-target 14.0 --output-partial-info-plist "$TMP/partial.plist" >/dev/null
cp "$TMP/Assets.car" "$TMP/Hush.icns" Resources/
sips -s format png -Z 512 Resources/Hush.icns --out icon.png >/dev/null
rm -rf "$TMP"
