#!/bin/sh
# Usage: ./build.sh [install]. Set HUSH_SIGN_ID to override the signing identity.
set -e
cd "$(dirname "$0")"
APP=build/Hush.app
rm -rf "$APP" && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/"
cp Resources/Assets.car Resources/Hush.icns "$APP/Contents/Resources/"
for arch in arm64 x86_64; do
  swiftc -O -swift-version 5 -target "$arch-apple-macos14" Sources/*.swift -o "build/Hush-$arch"
done
lipo -create build/Hush-arm64 build/Hush-x86_64 -output "$APP/Contents/MacOS/Hush"
rm build/Hush-arm64 build/Hush-x86_64

# A real identity keeps macOS permissions across rebuilds; ad-hoc resets them.
ID=${HUSH_SIGN_ID:-$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Apple Development|Developer ID/ {print $2; exit}')}
codesign --force -s "${ID:--}" "$APP"

if [ "$1" = "install" ]; then
  pkill -x Hush || true
  rm -rf /Applications/Hush.app && cp -R "$APP" /Applications/
  open /Applications/Hush.app
fi
