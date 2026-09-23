import AppKit
import ServiceManagement

let musicID = "com.apple.Music"

enum Target: String, CaseIterable {
    case spotify = "Spotify", soundcloud = "SoundCloud", none = "Nothing"

    func open() {
        switch self {
        case .spotify: launch("com.spotify.client")
        case .soundcloud: NSWorkspace.shared.open(URL(string: "https://soundcloud.com/you/likes")!)
        case .none: break
        }
    }

    private func launch(_ id: String) {
        guard NSRunningApplication.runningApplications(withBundleIdentifier: id).isEmpty,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var enabled = UserDefaults.standard.object(forKey: "enabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(enabled, forKey: "enabled"); render() }
    }
    private var target = Target(rawValue: UserDefaults.standard.string(forKey: "target") ?? "") ?? .spotify {
        didSet { UserDefaults.standard.set(target.rawValue, forKey: "target"); render() }
    }

    func applicationDidFinishLaunching(_ note: Notification) {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(appLaunched(_:)), name: NSWorkspace.willLaunchApplicationNotification, object: nil)
        nc.addObserver(self, selector: #selector(appLaunched(_:)), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NSRunningApplication.runningApplications(withBundleIdentifier: musicID).forEach(block)
        render()
    }

    @objc private func appLaunched(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == musicID else { return }
        block(app)
    }

    private func block(_ app: NSRunningApplication) {
        guard enabled else { return }
        app.forceTerminate()
        target.open()
    }

    private func render() {
        item.button?.image = NSImage(systemSymbolName: enabled ? "music.note" : "music.note.slash", accessibilityDescription: "PlayKey")
        let menu = NSMenu()
        menu.addItem(toggle("Block Apple Music", enabled, #selector(toggleEnabled)))
        let open = NSMenuItem(title: "Open instead", action: nil, keyEquivalent: "")
        open.submenu = NSMenu()
        for t in Target.allCases {
            let mi = toggle(t.rawValue, t == target, #selector(pickTarget(_:)))
            mi.representedObject = t.rawValue
            open.submenu?.addItem(mi)
        }
        menu.addItem(open)
        menu.addItem(toggle("Launch at login", SMAppService.mainApp.status == .enabled, #selector(toggleLogin)))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }

    private func toggle(_ title: String, _ on: Bool, _ action: Selector) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: "")
        mi.target = self
        mi.state = on ? .on : .off
        return mi
    }

    @objc private func toggleEnabled() { enabled.toggle() }

    @objc private func pickTarget(_ sender: NSMenuItem) {
        target = Target(rawValue: sender.representedObject as? String ?? "") ?? .spotify
    }

    @objc private func toggleLogin() {
        let svc = SMAppService.mainApp
        try? svc.status == .enabled ? svc.unregister() : svc.register()
        render()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
