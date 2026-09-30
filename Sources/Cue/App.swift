import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Cue: talking points above every window, invisible to screen sharing.
///
/// Lives in the menu bar (`LSUIElement`), no Dock icon — a Dock icon
/// would give the app away during a call.
final class AppState: NSObject, NSApplicationDelegate {
    static let shared = AppState()

    private var statusItem: NSStatusItem!
    private var panel: PrompterPanel?
    private var editor: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "text.alignleft", accessibilityDescription: "Cue")

        let menu = NSMenu()
        menu.addItem(item(String(localized: "Show / Hide"), "⌃⌥P", #selector(toggleMenu)))
        menu.addItem(item(String(localized: "Paste Notes from Clipboard"), "⌃⌥V", #selector(pasteMenu)))
        menu.addItem(item(String(localized: "Open Files…"), "", #selector(openFileMenu)))
        menu.addItem(item(String(localized: "Close Current File"), "", #selector(closeMenu)))
        menu.addItem(item(String(localized: "Edit Text…"), "", #selector(openEditor)))
        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Auto-Scroll"), "⌃⌥␣", #selector(runMenu)))
        menu.addItem(item(String(localized: "Voice-Paced Scrolling"), "", #selector(voiceMenu)))
        menu.addItem(item(String(localized: "Scroll"), "⌃⌥ ↑ ↓", nil))
        menu.addItem(item(String(localized: "Switch File"), "⌃⌥1 … ⌃⌥9", nil))
        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Check for Updates…"), "", #selector(updateMenu)))
        menu.addItem(item("Cue \(Updater.currentVersion)", "", nil))
        menu.addItem(item(String(localized: "Quit"), "", #selector(quit)))
        statusItem.menu = menu

        // If a shortcut is already taken, Carbon refuses silently — surface it
        // in the menu, otherwise the hotkey just "doesn't work" without a trace.
        var busy: [String] = []
        if !Hotkey.register(keyCode: 35, action: { self.toggle() }) { busy.append("⌃⌥P") }
        if !Hotkey.register(keyCode: 9, action: { Prompter.shared.pasteFromClipboard() }) { busy.append("⌃⌥V") }
        if !Hotkey.register(keyCode: 49, action: { Prompter.shared.toggleRun() }) { busy.append("⌃⌥␣") }
        if !Hotkey.register(keyCode: 126, action: { Prompter.shared.stop(); Prompter.shared.scroll(by: -60) }) { busy.append("⌃⌥↑") }
        if !Hotkey.register(keyCode: 125, action: { Prompter.shared.stop(); Prompter.shared.scroll(by: 60) }) { busy.append("⌃⌥↓") }

        // Number row: 1…9 switch between open files.
        for (n, code) in [18, 19, 20, 21, 23, 22, 26, 28, 25].enumerated() {
            Hotkey.register(keyCode: UInt32(code)) { Prompter.shared.select(n) }
        }

        if !busy.isEmpty {
            let i = NSMenuItem(title: "⚠︎ " + String(localized: "Taken by another app: \(busy.joined(separator: ", "))"),
                               action: nil, keyEquivalent: "")
            i.isEnabled = false
            menu.insertItem(i, at: 0)
        }

        show()
        Updater.check(interactive: false)
    }

    func showUpdateAvailable(_ tag: String) {
        guard let menu = statusItem.menu else { return }
        menu.insertItem(item("⬆ " + String(localized: "Update to Cue \(tag)…"), "", #selector(updateMenu)), at: 0)
    }

    private func item(_ title: String, _ hint: String, _ sel: Selector?) -> NSMenuItem {
        let i = NSMenuItem(title: hint.isEmpty ? title : "\(title)   \(hint)",
                           action: sel, keyEquivalent: "")
        i.target = self
        if sel == nil { i.isEnabled = false }
        return i
    }

    // MARK: - Panel

    func toggle() {
        if panel?.isVisible == true { hide() } else { show() }
    }

    private func show() {
        if panel == nil { panel = PrompterPanel() }
        panel?.orderFrontRegardless()
    }

    private func hide() {
        panel?.saveFrame()
        panel?.orderOut(nil)
    }

    // MARK: - Menu

    @objc private func toggleMenu() { toggle() }
    @objc private func pasteMenu() { Prompter.shared.pasteFromClipboard() }
    @objc private func runMenu() { Prompter.shared.toggleRun() }
    @objc private func voiceMenu() { Prompter.shared.toggleVoice() }
    @objc private func openFileMenu() { Prompter.shared.openFiles() }
    @objc private func closeMenu() { Prompter.shared.closeCurrent() }
    @objc private func updateMenu() { Updater.check(interactive: true) }
    @objc private func quit() { panel?.saveFrame(); NSApp.terminate(nil) }

    /// Editing only works in a regular window: the panel deliberately
    /// never takes focus, so you can't type into it.
    @objc private func openEditor() {
        if editor == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
                             styleMask: [.titled, .closable, .resizable],
                             backing: .buffered, defer: false)
            w.title = String(localized: "Notes")
            w.center()
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: EditorView(p: Prompter.shared))
            editor = w
        }
        NSApp.activate(ignoringOtherApps: true)
        editor?.makeKeyAndOrderFront(nil)
    }
}

private struct EditorView: View {
    @ObservedObject var p: Prompter

    var body: some View {
        TextEditor(text: $p.text)
            .font(.system(size: 14))
            .padding(8)
    }
}
