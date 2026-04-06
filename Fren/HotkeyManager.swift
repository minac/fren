import Cocoa
import Carbon.HIToolbox

final class HotkeyManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hotKeyRef: EventHotKeyRef?
    var onToggle: (() -> Void)?

    func start() {
        // Try CGEvent tap first (requires Accessibility permission)
        if startEventTap() {
            NSLog("[Fren] Global hotkey registered via CGEvent tap")
            return
        }

        NSLog("[Fren] CGEvent tap failed — falling back to Carbon hotkey")
        startCarbonHotKey()
    }

    // MARK: - CGEvent Tap (preferred — can suppress the event)

    private func startEventTap() -> Bool {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon else { return Unmanaged.passRetained(event) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
            return manager.handleEvent(proxy: proxy, type: type, event: event)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: selfPtr
        ) else {
            NSLog("[Fren] Failed to create CGEvent tap — Accessibility permission may not be granted")
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // Re-enable tap if it gets disabled by the system
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        // ⌥ + T (keyCode 17 = T)
        if keyCode == 17 && flags.contains(.maskAlternate)
            && !flags.contains(.maskCommand)
            && !flags.contains(.maskControl)
            && !flags.contains(.maskShift) {
            DispatchQueue.main.async { [weak self] in
                self?.onToggle?()
            }
            return nil // consume the event
        }

        return Unmanaged.passRetained(event)
    }

    // MARK: - Carbon Hot Key (fallback — always works but doesn't suppress the key)

    private func startCarbonHotKey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4652454E), // "FREN"
                                      id: 1)
        var ref: EventHotKeyRef?

        // kVK_ANSI_T = 0x11 (17), optionKey = 0x0800
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard status == noErr else {
            NSLog("[Fren] Failed to register Carbon hotkey: \(status)")
            return
        }

        hotKeyRef = ref

        // Install a Carbon event handler for the hot key
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, refcon -> OSStatus in
                guard let refcon else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.onToggle?()
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            nil
        )

        NSLog("[Fren] Global hotkey registered via Carbon RegisterEventHotKey")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
        eventTap = nil
        runLoopSource = nil
        hotKeyRef = nil
    }

    deinit {
        stop()
    }
}
