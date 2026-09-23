# How it works

Hush is about 500 lines of Swift with no dependencies. It uses public AppKit and CoreAudio APIs, plus Carbon for the global hotkey.

## Design rules

- React to system events. Do not poll device lists or app state.
- Keep one background timer at most, with tolerance so macOS can group its wakeups.
- Never launch an app by accident. Spotify commands go only to a running Spotify.

## Components

| File | Role |
| --- | --- |
| `main.swift` | App entry. Runs as a menu bar accessory with no Dock icon. |
| `AppDelegate.swift` | Menu bar icon and menu. The menu is rebuilt each time it opens, so it always shows current state. |
| `MusicBlocker.swift` | Watches `NSWorkspace` launch notifications and force quits Apple Music. |
| `Players.swift` | Spotify control, now playing, last used player, and call detection. |
| `AudioRouter.swift` | Mic rule, output switching, mute, and per-device volume. |
| `Audio.swift` | Thin CoreAudio wrapper. |
| `HotKey.swift` | Carbon global hotkey. It needs no Accessibility permission. |
| `Prefs.swift` | Settings in `UserDefaults`. |

## Play key

When no app owns Now Playing, the play key makes macOS launch Apple Music. Hush gets `willLaunchApplication` and `didLaunchApplication` notifications, quits Music, and opens the chosen player.

**Last used** is based on CoreAudio process objects. Every 3 seconds Hush reads `kAudioProcessPropertyIsRunningOutput` for each process. Spotify output marks Spotify as last used. Browser output marks SoundCloud.

## Now playing

Spotify posts `com.spotify.client.PlaybackStateChanged` as a distributed notification with the track name, artist, and player state. Hush listens for it. No permission is needed.

## Mic and output

Hush adds CoreAudio property listeners for:

- `kAudioHardwarePropertyDevices`: devices connect or disconnect
- `kAudioHardwarePropertyDefaultInputDevice`: the default mic changes
- `kAudioHardwarePropertyDefaultOutputDevice`: the default output changes

When the default mic has a Bluetooth transport type, Hush sets the default input to the Studio Display mic. If that is not connected, it uses the built-in mic.

When a Bluetooth output device appears, Hush makes it the default output. When one disappears, Hush picks the Studio Display speakers or the built-in speakers.

## Mute

Mute sets `kAudioDevicePropertyMute` on every input device, so a device switch cannot unmute you. Devices that connect while muted are muted too.

## Volume per device

Hush listens to the virtual main volume of the current output device and stores it by device name. When the output changes, it restores the stored volume.

## Calls

The same 3 second scan reads `kAudioProcessPropertyIsRunningInput`. A known call app or a browser using the mic counts as a call. When a call starts while Spotify plays, Hush pauses it. When the call ends, Hush resumes playback, but only if Hush paused it.
