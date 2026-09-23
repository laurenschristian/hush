import Carbon

final class HotKey {
    private var ref: EventHotKeyRef?
    private let handler: () -> Void

    init(keyCode: Int, modifiers: Int, handler: @escaping () -> Void) {
        self.handler = handler
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, ctx in
            Unmanaged<HotKey>.fromOpaque(ctx!).takeUnretainedValue().handler()
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
        RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), EventHotKeyID(signature: 0x48555348, id: 1), GetApplicationEventTarget(), 0, &ref)
    }
}
