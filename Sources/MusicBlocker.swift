import AppKit

final class MusicBlocker {
    private static let musicID = "com.apple.Music"
    private let players: Players

    init(players: Players) {
        self.players = players
        let nc = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willLaunchApplicationNotification, NSWorkspace.didLaunchApplicationNotification] {
            nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
                self?.block(app)
            }
        }
        NSRunningApplication.runningApplications(withBundleIdentifier: Self.musicID).forEach(block)
    }

    private func block(_ app: NSRunningApplication) {
        guard Prefs.blockMusic, app.bundleIdentifier == Self.musicID, !app.isTerminated else { return }
        app.forceTerminate()
        players.open(Prefs.target)
    }
}
