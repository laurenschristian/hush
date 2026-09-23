# Hush

A small macOS menu bar app that keeps your audio setup the way you want it.

## Features

**Play key**
- Stops Apple Music from launching when you press play
- Opens your last used player instead (Spotify or SoundCloud), and Spotify starts playing
- Shows the current Spotify track in the menu bar

**AirPods and Bluetooth**
- Never uses a Bluetooth mic. When AirPods take over the mic, Hush switches it back to the Studio Display mic, or the MacBook mic. AirPods stay in full quality audio mode.
- Switches output to headphones when they connect, and back to the speakers when they disconnect

Hush reacts to CoreAudio events at the moment they happen. It does not poll the device list.

Every feature can be turned off from the menu bar.

## Install

Requires macOS 14+ and the Xcode command line tools.

```sh
git clone https://github.com/laurenschristian/hush.git
cd hush
./build.sh install
```

This builds the app, ad-hoc signs it, copies it to `/Applications`, and starts it. Turn on "Launch at login" from the menu.

The first time Hush tells Spotify to play, macOS asks for Automation permission. Ad-hoc builds change signature, so macOS may ask again after a rebuild.

## How it works

| Feature | Mechanism |
| --- | --- |
| Block Apple Music | `NSWorkspace` launch notifications |
| Last used player | CoreAudio process objects (`kAudioProcessPropertyIsRunningOutput`) |
| Now playing | Spotify `PlaybackStateChanged` distributed notification |
| Mic and output switching | CoreAudio property listeners on the device list and default devices |

Limits:
- Browsers expose no per-tab info, so any browser audio counts as SoundCloud for "Last used".
- Now playing supports Spotify only. macOS no longer gives third-party apps access to the system Now Playing data.

## Project layout

```
Sources/
  main.swift          app entry
  AppDelegate.swift   menu bar UI
  MusicBlocker.swift  Apple Music blocking
  Players.swift       Spotify, SoundCloud, last used tracking
  AudioRouter.swift   mic and output rules
  Audio.swift         CoreAudio helpers
  Prefs.swift         settings
```

## Uninstall

Quit from the menu bar, then delete `/Applications/Hush.app`.

## License

MIT
