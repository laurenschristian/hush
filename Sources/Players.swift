import AppKit

enum Target: String, CaseIterable {
    case lastUsed = "Last used", spotify = "Spotify", soundcloud = "SoundCloud", none = "Nothing"
}

enum Player: String {
    case spotify, browser
}

final class Players {
    static let spotifyID = "com.spotify.client"
    private static let browserPrefixes = ["org.mozilla.", "com.google.Chrome", "com.apple.WebKit", "com.apple.Safari", "company.thebrowser", "com.brave."]

    private(set) var track: (title: String, artist: String)?
    var onChange: (() -> Void)?

    init() {
        DistributedNotificationCenter.default().addObserver(forName: .init("com.spotify.client.PlaybackStateChanged"), object: nil, queue: .main) { [weak self] note in
            let info = note.userInfo ?? [:]
            let playing = info["Player State"] as? String == "Playing"
            self?.track = playing ? (info["Name"] as? String ?? "", info["Artist"] as? String ?? "") : nil
            if playing { Prefs.lastPlayer = .spotify }
            self?.onChange?()
        }
        // No public per-tab API, so any browser audio counts as SoundCloud.
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            let ids = Audio.playingBundleIDs()
            if ids.contains(where: { $0.hasPrefix(Self.spotifyID) }) {
                Prefs.lastPlayer = .spotify
            } else if ids.contains(where: { id in Self.browserPrefixes.contains(where: id.hasPrefix) }) {
                Prefs.lastPlayer = .browser
            }
        }
    }

    func open(_ target: Target) {
        switch target {
        case .lastUsed: Prefs.lastPlayer == .browser ? openSoundCloud() : playSpotify()
        case .spotify: playSpotify()
        case .soundcloud: openSoundCloud()
        case .none: break
        }
    }

    func playPause() { spotify("playpause") }

    private func openSoundCloud() {
        NSWorkspace.shared.open(URL(string: "https://soundcloud.com/you/likes")!)
    }

    private func playSpotify() {
        if !NSRunningApplication.runningApplications(withBundleIdentifier: Self.spotifyID).isEmpty {
            return spotify("play")
        }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.spotifyID) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: .init()) { _, _ in
            // Spotify ignores play commands until its UI has loaded.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.spotify("play") }
        }
    }

    private func spotify(_ command: String) {
        NSAppleScript(source: "tell application id \"\(Self.spotifyID)\" to \(command)")?.executeAndReturnError(nil)
    }
}
