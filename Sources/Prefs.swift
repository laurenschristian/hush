import Foundation

enum Prefs {
    private static let store = UserDefaults.standard

    private static func bool(_ key: String) -> Bool { store.object(forKey: key) as? Bool ?? true }

    static var blockMusic: Bool {
        get { bool("blockMusic") }
        set { store.set(newValue, forKey: "blockMusic") }
    }
    static var blockBluetoothMic: Bool {
        get { bool("blockBluetoothMic") }
        set { store.set(newValue, forKey: "blockBluetoothMic") }
    }
    static var followHeadphones: Bool {
        get { bool("followHeadphones") }
        set { store.set(newValue, forKey: "followHeadphones") }
    }
    static var target: Target {
        get { Target(rawValue: store.string(forKey: "target") ?? "") ?? .lastUsed }
        set { store.set(newValue.rawValue, forKey: "target") }
    }
    static var lastPlayer: Player {
        get { Player(rawValue: store.string(forKey: "lastPlayer") ?? "") ?? .spotify }
        set { store.set(newValue.rawValue, forKey: "lastPlayer") }
    }
}
