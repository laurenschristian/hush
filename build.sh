#!/bin/sh
set -e
cd "$(dirname "$0")"
APP=build/PlayKey.app
rm -rf "$APP" && mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/"
swiftc -O Sources/main.swift -o "$APP/Contents/MacOS/PlayKey"
codesign --force -s - "$APP"
if [ "$1" = "install" ]; then
  pkill -x PlayKey || true
  rm -rf /Applications/PlayKey.app && cp -R "$APP" /Applications/
  open /Applications/PlayKey.app
fi
