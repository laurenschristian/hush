#!/bin/sh
set -e
cd "$(dirname "$0")"
APP=build/Hush.app
rm -rf "$APP" && mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/"
swiftc -O -swift-version 5 Sources/*.swift -o "$APP/Contents/MacOS/Hush"
codesign --force -s - "$APP"
if [ "$1" = "install" ]; then
  pkill -x Hush || true
  rm -rf /Applications/Hush.app && cp -R "$APP" /Applications/
  open /Applications/Hush.app
fi
