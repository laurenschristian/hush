import CoreAudio

final class AudioRouter {
    private var known: [AudioDeviceID: AudioDevice] = [:]

    init() {
        known = Dictionary(uniqueKeysWithValues: Audio.devices().map { ($0.id, $0) })
        Audio.listen(kAudioHardwarePropertyDevices) { [weak self] in self?.devicesChanged() }
        Audio.listen(kAudioHardwarePropertyDefaultInputDevice) { [weak self] in self?.enforceMic() }
        enforceMic()
    }

    private func devicesChanged() {
        let devices = Audio.devices()
        let current = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
        defer { known = current }

        if Prefs.followHeadphones {
            if let added = devices.first(where: { known[$0.id] == nil && $0.isBluetooth && $0.hasOutput }) {
                Audio.setDefault(added.id, input: false)
            } else if known.values.contains(where: { current[$0.id] == nil && $0.isBluetooth && $0.hasOutput }),
                      let speakers = preferred(devices, output: true) {
                Audio.setDefault(speakers.id, input: false)
            }
        }
        enforceMic()
    }

    private func enforceMic() {
        guard Prefs.blockBluetoothMic,
              let mic = Audio.defaultDevice(input: true), mic.isBluetooth,
              let fallback = preferred(Audio.devices(), output: false) else { return }
        Audio.setDefault(fallback.id, input: true)
    }

    private func preferred(_ devices: [AudioDevice], output: Bool) -> AudioDevice? {
        let usable = devices.filter { output ? $0.hasOutput : $0.hasInput }
        return usable.first(where: \.isStudioDisplay) ?? usable.first(where: \.isBuiltIn)
    }
}
