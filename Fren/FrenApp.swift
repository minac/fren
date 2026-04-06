import SwiftUI
import Cocoa

@main
struct FrenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayPanel: OverlayPanel?
    private var clickOutsideMonitor: Any?
    private let hotkeyManager = HotkeyManager()
    private var showingAPIKeyPrompt = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock (belt-and-suspenders with LSUIElement)
        NSApp.setActivationPolicy(.accessory)

        if !Config.hasAPIKey {
            showAPIKeyPrompt()
        }

        hotkeyManager.onToggle = { [weak self] in
            self?.toggleOverlay()
        }
        hotkeyManager.start()
    }

    private func toggleOverlay() {
        if let panel = overlayPanel, panel.isVisible {
            dismissOverlay()
        } else {
            showOverlay()
        }
    }

    private func dismissOverlay() {
        overlayPanel?.dismiss()
        overlayPanel = nil
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }

    private func showOverlay() {
        if !Config.hasAPIKey {
            showAPIKeyPrompt()
            return
        }

        let view = TranslationView(onDismiss: { [weak self] in
            self?.dismissOverlay()
        })

        let panel = OverlayPanel(contentView: view)
        overlayPanel = panel

        clickOutsideMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let panel = self?.overlayPanel, panel.isVisible else { return event }
            if event.window != panel {
                self?.dismissOverlay()
            }
            return event
        }

        panel.showCentered()
    }

    private func showAPIKeyPrompt() {
        guard !showingAPIKeyPrompt else { return }
        showingAPIKeyPrompt = true

        let alert = NSAlert()
        alert.messageText = "DeepL API Key Required"
        alert.informativeText = "Paste your DeepL API key below.\nGet a free key at: https://www.deepl.com/pro#developer"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Quit")

        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputField.placeholderString = "Paste your DeepL API key"
        alert.accessoryView = inputField

        let response = alert.runModal()
        showingAPIKeyPrompt = false

        if response == .alertFirstButtonReturn {
            let key = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty {
                if !Config.setAPIKey(key) {
                    let failAlert = NSAlert()
                    failAlert.messageText = "Could not save API key"
                    failAlert.informativeText = "The key could not be stored in the macOS Keychain."
                    failAlert.runModal()
                    NSApp.terminate(nil)
                }
            } else {
                NSApp.terminate(nil)
            }
        } else {
            NSApp.terminate(nil)
        }
    }
}
