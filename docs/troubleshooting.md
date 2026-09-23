# Troubleshooting

## "Hush is damaged and can't be opened"

Hush is not notarized. Remove the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/Hush.app
```

## Spotify does not start playing

Hush needs Automation permission to control Spotify. Open **System Settings > Privacy & Security > Automation**, find Hush, and turn on Spotify.

Release builds are ad-hoc signed. After an upgrade, macOS can ask for permission again.

## The mic still switches to AirPods

1. Open the Hush menu and check that **Never use Bluetooth mic** is on.
2. Check that no other tool also switches audio devices, for example a Raycast audio extension or a LaunchAgent. Two tools fight each other.
3. Check that **Mic:** in the menu shows your Studio Display or MacBook mic.

## The mute hotkey does nothing

Another app may use `⌃⌥M`. Quit the other app, or use **Mute mic** in the menu.

## Now playing does not show

Now playing supports Spotify only. It appears when Spotify starts or changes a track.

## Reset all settings

```sh
defaults delete com.laurenschristian.hush
```

Then quit and reopen Hush.
