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
    static var pauseOnDisconnect: Bool {
        get { bool("pauseOnDisconnect") }
        set { store.set(newValue, forKey: "pauseOnDisconnect") }
    }
    static var volumePerDevice: Bool {
        get { bool("volumePerDevice") }
        set { store.set(newValue, forKey: "volumePerDevice") }
    }
    static var callMode: Bool {
        get { bool("callMode") }
        set { store.set(newValue, forKey: "callMode") }
    }
    static var volumes: [String: Float32] {
        get { store.dictionary(forKey: "volumes") as? [String: Float32] ?? [:] }
        set { store.set(newValue, forKey: "volumes") }
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
