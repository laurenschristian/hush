# Hush

A small macOS menu bar app that keeps your audio setup the way you want it.

## Features

**Play key**
- Stops Apple Music from launching when you press play
- Opens your last used player instead (Spotify or SoundCloud), and Spotify starts playing
- Shows the current Spotify track in the menu bar

**Mic**
- `⌃⌥M` mutes or unmutes the mic in every app. The menu bar icon turns red while muted.

**Calls**
- Pauses Spotify when a Teams, Zoom, FaceTime, Slack, or browser call starts, and resumes it after the call

**AirPods and Bluetooth**
- Never uses a Bluetooth mic. When AirPods take over the mic, Hush switches it back to the Studio Display mic, or the MacBook mic. AirPods stay in full quality audio mode.
- Switches output to headphones when they connect, and back to the speakers when they disconnect
- Pauses Spotify when headphones disconnect, so music does not jump to the speakers
- Remembers the volume for each output device

Hush reacts to CoreAudio events at the moment they happen. It does not poll the device list.

Every feature can be turned off from the menu bar.

## Install

Requires macOS 14+.

```sh
brew install laurenschristian/tap/hush
```

Then turn on "Launch at login" from the menu. The first time Hush tells Spotify to play, macOS asks for Automation permission.

### Build from source

Requires the Xcode command line tools.

```sh
git clone https://github.com/laurenschristian/hush.git
cd hush
./build.sh install
```

This builds a universal app, signs it, copies it to `/Applications`, and starts it. The script signs with your first Apple Development or Developer ID certificate, so macOS keeps permissions across rebuilds. Without one it falls back to ad-hoc signing. Set `HUSH_SIGN_ID` to choose an identity.

## Release

```sh
git tag v0.3.0 && git push --tags
```

The release workflow builds `Hush-v0.3.0.zip` and attaches it to a GitHub release. Then update `version` and `sha256` in `Casks/hush.rb` in [homebrew-tap](https://github.com/laurenschristian/homebrew-tap).

## How it works

| Feature | Mechanism |
| --- | --- |
| Block Apple Music | `NSWorkspace` launch notifications |
| Last used player | CoreAudio process objects (`kAudioProcessPropertyIsRunningOutput`) |
| Now playing | Spotify `PlaybackStateChanged` distributed notification |
| Mic and output switching | CoreAudio property listeners on the device list and default devices |
| Mic mute | `kAudioDevicePropertyMute` on every input device, Carbon global hotkey |
| Volume per device | Listener on the output device's virtual main volume |
| Call mode | CoreAudio process objects (`kAudioProcessPropertyIsRunningInput`) |

Limits:
- Browsers expose no per-tab info, so any browser audio counts as SoundCloud for "Last used".
- Now playing, pause on disconnect, and call mode control Spotify only. macOS no longer gives third-party apps access to the system Now Playing data.

## Project layout

```
Sources/
  main.swift          app entry
  AppDelegate.swift   menu bar UI
  MusicBlocker.swift  Apple Music blocking
  Players.swift       Spotify, SoundCloud, last used tracking
  AudioRouter.swift   mic, output, mute, and volume rules
  HotKey.swift        global hotkey
  Audio.swift         CoreAudio helpers
  Prefs.swift         settings
```

## Uninstall

Quit from the menu bar, then delete `/Applications/Hush.app`.

## License

MIT
