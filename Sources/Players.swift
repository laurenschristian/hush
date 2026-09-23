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
    private static let callPrefixes = ["com.microsoft.teams", "us.zoom.", "com.apple.FaceTime", "com.tinyspeck.slackmacgap", "com.hnc.Discord", "Cisco-Systems.Spark"]

    private(set) var track: (title: String, artist: String)?
    var onChange: (() -> Void)?
    private var inCall = false
    private var pausedForCall = false

    init() {
        DistributedNotificationCenter.default().addObserver(forName: .init("com.spotify.client.PlaybackStateChanged"), object: nil, queue: .main) { [weak self] note in
            let info = note.userInfo ?? [:]
            let playing = info["Player State"] as? String == "Playing"
            self?.track = playing ? (info["Name"] as? String ?? "", info["Artist"] as? String ?? "") : nil
            if playing { Prefs.lastPlayer = .spotify }
            self?.onChange?()
        }
        let timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.scan() }
        timer.tolerance = 2
    }

    private static func matches(_ ids: [String], _ prefixes: [String]) -> Bool {
        ids.contains { id in prefixes.contains(where: id.hasPrefix) }
    }

    private func scan() {
        // No public per-tab API, so any browser audio counts as SoundCloud.
        let playing = Audio.activeBundleIDs(input: false)
        if playing.contains(where: { $0.hasPrefix(Self.spotifyID) }) {
            Prefs.lastPlayer = .spotify
        } else if Self.matches(playing, Self.browserPrefixes) {
            Prefs.lastPlayer = .browser
        }

        // A browser using the mic is almost always a Meet or Teams web call.
        let call = Self.matches(Audio.activeBundleIDs(input: true), Self.callPrefixes + Self.browserPrefixes)
        guard call != inCall else { return }
        inCall = call
        if call, Prefs.callMode, track != nil {
            pause()
            pausedForCall = true
        } else if !call, pausedForCall {
            pausedForCall = false
            spotify("play")
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
    func pause() { spotify("pause") }

    private func openSoundCloud() {
        NSWorkspace.shared.open(URL(string: "https://soundcloud.com/you/likes")!)
    }

    private func playSpotify() {
        if spotifyRunning { return spotify("play") }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.spotifyID) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: .init()) { _, _ in
            // Spotify ignores play commands until its UI has loaded.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.spotify("play") }
        }
    }

    private var spotifyRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: Self.spotifyID).isEmpty
    }

    /// Only talks to a running Spotify; AppleScript would otherwise launch it.
    private func spotify(_ command: String) {
        guard spotifyRunning else { return }
        NSAppleScript(source: "tell application id \"\(Self.spotifyID)\" to \(command)")?.executeAndReturnError(nil)
    }
}
