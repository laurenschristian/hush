import AudioToolbox
import CoreAudio
import Foundation

struct AudioDevice {
    let id: AudioDeviceID
    let name: String
    let transport: UInt32
    let hasInput: Bool
    let hasOutput: Bool

    var isBluetooth: Bool { transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE }
    var isBuiltIn: Bool { transport == kAudioDeviceTransportTypeBuiltIn }
    var isStudioDisplay: Bool { name.contains("Studio Display") }
}

enum Audio {
    static let system = AudioObjectID(kAudioObjectSystemObject)

    static func address(_ sel: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: sel, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    static func get<T: BitwiseCopyable>(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, default value: T) -> T {
        var addr = address(sel, scope)
        var out = value
        var size = UInt32(MemoryLayout<T>.size)
        return AudioObjectGetPropertyData(obj, &addr, 0, nil, &size, &out) == noErr ? out : value
    }

    static func set<T: BitwiseCopyable>(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope, _ value: T) {
        var addr = address(sel, scope)
        var v = value
        AudioObjectSetPropertyData(obj, &addr, 0, nil, UInt32(MemoryLayout<T>.size), &v)
    }

    static func string(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector) -> String {
        var addr = address(sel)
        var out: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(obj, &addr, 0, nil, &size, &out) == noErr, let s = out else { return "" }
        return s.takeRetainedValue() as String
    }

    static func objects(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector) -> [AudioObjectID] {
        var addr = address(sel)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(obj, &addr, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        return AudioObjectGetPropertyData(obj, &addr, 0, nil, &size, &ids) == noErr ? ids : []
    }

    private static func hasStreams(_ id: AudioDeviceID, _ scope: AudioObjectPropertyScope) -> Bool {
        var addr = address(kAudioDevicePropertyStreams, scope)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr && size > 0
    }

    static func devices() -> [AudioDevice] {
        objects(system, kAudioHardwarePropertyDevices).map {
            AudioDevice(
                id: $0,
                name: string($0, kAudioObjectPropertyName),
                transport: get($0, kAudioDevicePropertyTransportType, default: UInt32(0)),
                hasInput: hasStreams($0, kAudioObjectPropertyScopeInput),
                hasOutput: hasStreams($0, kAudioObjectPropertyScopeOutput)
            )
        }
    }

    private static func defaultSelector(input: Bool) -> AudioObjectPropertySelector {
        input ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice
    }

    static func defaultDevice(input: Bool) -> AudioDevice? {
        let id = get(system, defaultSelector(input: input), default: AudioDeviceID(0))
        return devices().first { $0.id == id }
    }

    static func setDefault(_ id: AudioDeviceID, input: Bool) {
        set(system, defaultSelector(input: input), kAudioObjectPropertyScopeGlobal, id)
    }

    static func volume(_ id: AudioDeviceID) -> Float32? {
        let v = get(id, kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioObjectPropertyScopeOutput, default: Float32(-1))
        return v < 0 ? nil : v
    }

    static func setVolume(_ id: AudioDeviceID, _ value: Float32) {
        set(id, kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioObjectPropertyScopeOutput, value)
    }

    static func isMuted(_ id: AudioDeviceID) -> Bool {
        get(id, kAudioDevicePropertyMute, kAudioObjectPropertyScopeInput, default: UInt32(0)) != 0
    }

    static func setMuted(_ id: AudioDeviceID, _ muted: Bool) {
        set(id, kAudioDevicePropertyMute, kAudioObjectPropertyScopeInput, UInt32(muted ? 1 : 0))
    }

    static func listen(_ sel: AudioObjectPropertySelector, _ block: @escaping () -> Void) {
        var addr = address(sel)
        AudioObjectAddPropertyListenerBlock(system, &addr, .main) { _, _ in block() }
    }

    static func listen(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope, _ block: @escaping AudioObjectPropertyListenerBlock) {
        var addr = address(sel, scope)
        AudioObjectAddPropertyListenerBlock(obj, &addr, .main, block)
    }

    static func unlisten(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope, _ block: @escaping AudioObjectPropertyListenerBlock) {
        var addr = address(sel, scope)
        AudioObjectRemovePropertyListenerBlock(obj, &addr, .main, block)
    }

    /// Bundle IDs of processes currently playing audio (output) or recording it (input).
    static func activeBundleIDs(input: Bool) -> [String] {
        let sel = input ? kAudioProcessPropertyIsRunningInput : kAudioProcessPropertyIsRunningOutput
        return objects(system, kAudioHardwarePropertyProcessObjectList)
            .filter { get($0, sel, default: UInt32(0)) != 0 }
            .map { string($0, kAudioProcessPropertyBundleID) }
    }
}
