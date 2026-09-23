import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let players = Players()
    private var blocker: MusicBlocker?
    private var router: AudioRouter?

    func applicationDidFinishLaunching(_ note: Notification) {
        blocker = MusicBlocker(players: players)
        router = AudioRouter()
        players.onChange = { [weak self] in self?.renderButton() }
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        renderButton()
    }

    private func renderButton() {
        guard let button = item.button else { return }
        button.image = NSImage(systemSymbolName: Prefs.blockMusic ? "music.note" : "music.note.slash", accessibilityDescription: "Hush")
        button.imagePosition = .imageLeading
        if let t = players.track {
            let text = "\(t.title) · \(t.artist)"
            button.title = " " + (text.count > 32 ? text.prefix(31) + "…" : text)
        } else {
            button.title = ""
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if let t = players.track {
            menu.addItem(disabled("\(t.title) · \(t.artist)"))
        }
        menu.addItem(action("Play / Pause Spotify", #selector(playPause)))
        menu.addItem(.separator())

        menu.addItem(check("Block Apple Music", Prefs.blockMusic, #selector(toggleBlockMusic)))
        let open = NSMenuItem(title: "Open instead", action: nil, keyEquivalent: "")
        open.submenu = NSMenu()
        for t in Target.allCases {
            let mi = check(t.rawValue, t == Prefs.target, #selector(pickTarget(_:)))
            mi.representedObject = t.rawValue
            open.submenu?.addItem(mi)
        }
        menu.addItem(open)
        menu.addItem(.separator())

        menu.addItem(check("Never use Bluetooth mic", Prefs.blockBluetoothMic, #selector(toggleMic)))
        menu.addItem(check("Switch output to headphones", Prefs.followHeadphones, #selector(toggleFollow)))
        menu.addItem(disabled("Mic: \(Audio.defaultDevice(input: true)?.name ?? "none")"))
        menu.addItem(disabled("Output: \(Audio.defaultDevice(input: false)?.name ?? "none")"))
        menu.addItem(.separator())

        menu.addItem(check("Launch at login", SMAppService.mainApp.status == .enabled, #selector(toggleLogin)))
        menu.addItem(NSMenuItem(title: "Quit Hush", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func action(_ title: String, _ sel: Selector) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: sel, keyEquivalent: "")
        mi.target = self
        return mi
    }

    private func check(_ title: String, _ on: Bool, _ sel: Selector) -> NSMenuItem {
        let mi = action(title, sel)
        mi.state = on ? .on : .off
        return mi
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        mi.isEnabled = false
        return mi
    }

    @objc private func playPause() { players.playPause() }
    @objc private func toggleBlockMusic() { Prefs.blockMusic.toggle(); renderButton() }
    @objc private func toggleMic() { Prefs.blockBluetoothMic.toggle() }
    @objc private func toggleFollow() { Prefs.followHeadphones.toggle() }

    @objc private func pickTarget(_ sender: NSMenuItem) {
        Prefs.target = Target(rawValue: sender.representedObject as? String ?? "") ?? .lastUsed
    }

    @objc private func toggleLogin() {
        let svc = SMAppService.mainApp
        try? svc.status == .enabled ? svc.unregister() : svc.register()
    }
}
