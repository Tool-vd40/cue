import AppKit
import AVFoundation
import Combine
import UniformTypeIdentifiers

/// One open text: pitch, Q&A, numbers — anything.
/// Each keeps its own scroll position, otherwise switching back and forth
/// loses your place.
struct Doc: Codable {
    var name: String
    var text: String
    var offset: CGFloat = 0
}

/// Prompter state.
///
/// Scrolling isn't a `ScrollView`, it's the text shifted by `offset`. That way
/// the wheel, hotkeys and auto-scroll all behave the same: they move one number.
final class Prompter: ObservableObject {
    static let shared = Prompter()

    @Published private(set) var docs: [Doc] = []
    @Published private(set) var current = 0

    @Published var offset: CGFloat = 0
    @Published var isRunning = false
    @Published var voiceMode = false
    @Published var fontSize: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "fontSize"))
    /// Points per second when auto-scrolling.
    @Published var speed: Double = 25

    /// Laid-out text height and window height — so we never scroll into the void.
    var contentHeight: CGFloat = 0
    var viewHeight: CGFloat = 0

    private let gate = VoiceGate()
    private var timer: Timer?

    private init() {
        if fontSize < 10 { fontSize = 22 }
        docs = Self.restore()
        current = min(UserDefaults.standard.integer(forKey: "current"), max(0, docs.count - 1))
        offset = docs.indices.contains(current) ? docs[current].offset : 0
    }

    // MARK: - Text

    /// Current text. Writes go into the open file, not past it.
    var text: String {
        get { docs.indices.contains(current) ? docs[current].text : "" }
        set {
            if docs.isEmpty {
                docs = [Doc(name: String(localized: "Notes"), text: newValue)]
                current = 0
            } else {
                docs[current].text = newValue
            }
            save()
        }
    }

    // MARK: - Files

    func select(_ i: Int) {
        guard docs.indices.contains(i) else { return }
        if docs.indices.contains(current), i != current { docs[current].offset = offset }
        current = i
        offset = docs[i].offset
        stop()
        save()
    }

    /// Open a file. If it's already open, refresh it and switch to it,
    /// otherwise identical tabs pile up during a call.
    func load(_ url: URL) {
        guard let s = try? String(contentsOf: url, encoding: .utf8) else {
            NSSound.beep()
            return
        }
        put(name: url.deletingPathExtension().lastPathComponent, text: s)
    }

    private func put(name: String, text: String) {
        if let i = docs.firstIndex(where: { $0.name == name }) {
            docs[i].text = text
            docs[i].offset = 0
            select(i)
        } else {
            docs.append(Doc(name: name, text: text))
            select(docs.count - 1)
        }
    }

    /// File picker. The panel never takes focus, so bring the app
    /// to the front. Several files can be picked at once.
    func openFiles() {
        let p = NSOpenPanel()
        p.allowedContentTypes = [.plainText, .text, .data]
        p.allowsMultipleSelection = true
        p.message = String(localized: "Files with your notes: .txt, .md — any text")
        NSApp.activate(ignoringOtherApps: true)
        guard p.runModal() == .OK else { return }
        p.urls.forEach(load)
    }

    func closeCurrent() {
        guard docs.indices.contains(current) else { return }
        docs.remove(at: current)
        current = max(0, min(current, docs.count - 1))
        offset = docs.indices.contains(current) ? docs[current].offset : 0
        stop()
        save()
    }

    func pasteFromClipboard() {
        guard let s = NSPasteboard.general.string(forType: .string), !s.isEmpty else { return }
        put(name: String(localized: "Clipboard"), text: s)
    }

    // MARK: - Scrolling

    private var maxOffset: CGFloat { max(0, contentHeight - viewHeight + 24) }

    func scroll(by delta: CGFloat) {
        offset = min(max(0, offset + delta), maxOffset)
    }

    func toTop() {
        offset = 0
        stop()
    }

    func setFont(_ size: CGFloat) {
        fontSize = min(max(12, size), 64)
        UserDefaults.standard.set(Double(fontSize), forKey: "fontSize")
    }

    func toggleRun() {
        voiceMode = false
        gate.stop()
        isRunning ? stop() : start()
    }

    /// Ask for the mic when voice mode is switched on, not at launch:
    /// the prompter must work without asking for anything.
    func toggleVoice() {
        if voiceMode {
            voiceMode = false
            gate.stop()
            stop()
            return
        }
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] ok in
            DispatchQueue.main.async {
                guard let self else { return }
                guard ok, self.gate.start() else {
                    NSSound.beep()
                    return
                }
                self.voiceMode = true
                self.start()
            }
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        // At the bottom already — restart from the top, or the button looks broken.
        if offset >= maxOffset { offset = 0 }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.voiceMode && !self.gate.isSpeaking { return }
            self.scroll(by: CGFloat(self.speed) / 60)
            if self.offset >= self.maxOffset { self.stop() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    // MARK: - Persistence

    private func save() {
        var copy = docs
        if copy.indices.contains(current) { copy[current].offset = offset }
        UserDefaults.standard.set(try? JSONEncoder().encode(copy), forKey: "docs")
        UserDefaults.standard.set(current, forKey: "current")
    }

    private static func restore() -> [Doc] {
        if let data = UserDefaults.standard.data(forKey: "docs"),
           let docs = try? JSONDecoder().decode([Doc].self, from: data), !docs.isEmpty {
            return docs
        }
        // Migration from the old version with a single text.
        if let old = UserDefaults.standard.string(forKey: "script"), !old.isEmpty {
            return [Doc(name: String(localized: "Notes"), text: old)]
        }
        return []
    }
}
