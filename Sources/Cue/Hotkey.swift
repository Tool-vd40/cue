import AppKit
import Carbon.HIToolbox

/// Global hotkeys via Carbon. Works without any permissions, unlike
/// anything that goes through Accessibility.
///
/// Exactly one handler is installed for the whole app. It used to be
/// installed per hotkey, and one keypress fired as many times as there
/// were hotkeys registered.
enum Hotkey {
    private static var actions: [UInt32: () -> Void] = [:]
    private static var refs: [EventHotKeyRef] = []
    private static var handler: EventHandlerRef?
    private static var nextID: UInt32 = 1

    /// Returns false if the shortcut is already taken by another app.
    @discardableResult
    static func register(keyCode: UInt32,
                         modifiers: UInt32 = UInt32(controlKey | optionKey),
                         action: @escaping () -> Void) -> Bool {
        installHandlerOnce()

        let id = nextID
        nextID += 1
        actions[id] = action

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers,
                                         EventHotKeyID(signature: OSType(0x43554520), id: id),  // 'CUE '
                                         GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else {
            actions[id] = nil
            FileHandle.standardError.write(
                "hotkey keyCode=\(keyCode) not registered, status \(status)\n".data(using: .utf8)!)
            return false
        }
        refs.append(ref)
        return true
    }

    private static func installHandlerOnce() {
        guard handler == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &id)
            DispatchQueue.main.async { Hotkey.actions[id.id]?() }
            return noErr
        }, 1, &spec, nil, &handler)
    }
}
