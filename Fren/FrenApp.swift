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
            panel.dismiss()
            overlayPanel = nil
        } else {
            showOverlay()
        }
    }

    private func showOverlay() {
        if !Config.hasAPIKey {
            showAPIKeyPrompt()
            return
        }

        let view = TranslationView(onDismiss: { [weak self] in
            self?.overlayPanel?.dismiss()
            self?.overlayPanel = nil
        })

        let panel = OverlayPanel(contentView: view)
        overlayPanel = panel

        // Dismiss on click outside
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let panel = self?.overlayPanel, panel.isVisible else { return event }
            let locationInWindow = event.locationInWindow
            if event.window != panel {
                panel.dismiss()
                self?.overlayPanel = nil
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
                _ = Config.setAPIKey(key)
            } else {
                NSApp.terminate(nil)
            }
        } else {
            NSApp.terminate(nil)
        }
    }
}
