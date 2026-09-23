# PlayKey

A tiny macOS menu bar app that stops Apple Music from hijacking your play key.

When you press play and no player is active, macOS launches Apple Music. PlayKey quits it right away and opens your player instead.

## Features

- Blocks Apple Music from launching
- Opens Spotify or SoundCloud (web) instead, or nothing
- Toggle blocking from the menu bar
- Launch at login
- No dependencies, one Swift file

## Install

Requires macOS 13+ and Xcode command line tools.

```sh
git clone https://github.com/laurenschristian/playkey.git
cd playkey
./build.sh install
```

This builds the app, ad-hoc signs it, copies it to `/Applications`, and starts it.

## Media keys

Play, pause, next, and previous go to whatever app macOS shows as "Now Playing". Once Spotify or a SoundCloud browser tab is playing, the keys control it directly. PlayKey only steps in when Apple Music tries to start.

## Uninstall

Quit from the menu bar, then delete `/Applications/PlayKey.app`.

## License

MIT
