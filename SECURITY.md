# Security

## Reporting a vulnerability

Do not open a public issue. Use [GitHub private vulnerability reporting](https://github.com/laurenschristian/hush/security/advisories/new).

## What Hush can access

- **Audio devices:** Hush reads and changes the default mic, the default output, mute, and volume through CoreAudio.
- **Running apps:** Hush sees app launches and can quit Apple Music.
- **Spotify:** Hush sends play and pause commands through Apple Events, after you allow it.

Hush does not record audio, does not use the network, and stores only its settings in `~/Library/Preferences/com.laurenschristian.hush.plist`.
