import AudioToolbox
import CoreAudio

final class AudioRouter {
    var onHeadphonesRemoved: (() -> Void)?
    private(set) var micMuted = false
    private var known: [AudioDeviceID: AudioDevice] = [:]
    private var watchedOutput: AudioDeviceID?
    private let volumeSel = kAudioHardwareServiceDeviceProperty_VirtualMainVolume
    private let saveVolume: AudioObjectPropertyListenerBlock = { _, _ in
        guard Prefs.volumePerDevice, let out = Audio.defaultDevice(input: false), let v = Audio.volume(out.id) else { return }
        Prefs.volumes[out.name] = v
    }

    init() {
        known = Dictionary(uniqueKeysWithValues: Audio.devices().map { ($0.id, $0) })
        micMuted = Audio.defaultDevice(input: true).map { Audio.isMuted($0.id) } ?? false
        Audio.listen(kAudioHardwarePropertyDevices) { [weak self] in self?.devicesChanged() }
        Audio.listen(kAudioHardwarePropertyDefaultInputDevice) { [weak self] in self?.enforceMic() }
        Audio.listen(kAudioHardwarePropertyDefaultOutputDevice) { [weak self] in self?.outputChanged() }
        enforceMic()
        outputChanged()
    }

    func toggleMute() {
        micMuted.toggle()
        applyMute()
    }

    private func applyMute() {
        for d in Audio.devices() where d.hasInput { Audio.setMuted(d.id, micMuted) }
    }

    private func devicesChanged() {
        let devices = Audio.devices()
        let current = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
        let added = devices.first { known[$0.id] == nil && $0.isBluetooth && $0.hasOutput }
        let removed = known.values.contains { current[$0.id] == nil && $0.isBluetooth && $0.hasOutput }
        known = current

        if removed, Prefs.pauseOnDisconnect { onHeadphonesRemoved?() }
        if Prefs.followHeadphones {
            if let added {
                Audio.setDefault(added.id, input: false)
            } else if removed, let speakers = preferred(devices, output: true) {
                Audio.setDefault(speakers.id, input: false)
            }
        }
        if micMuted { applyMute() }
        enforceMic()
    }

    private func outputChanged() {
        if let old = watchedOutput { Audio.unlisten(old, volumeSel, kAudioObjectPropertyScopeOutput, saveVolume) }
        guard let out = Audio.defaultDevice(input: false) else { return }
        watchedOutput = out.id
        if Prefs.volumePerDevice, let v = Prefs.volumes[out.name] { Audio.setVolume(out.id, v) }
        Audio.listen(out.id, volumeSel, kAudioObjectPropertyScopeOutput, saveVolume)
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
