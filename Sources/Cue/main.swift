import AppKit
import AVFoundation
import SwiftUI

// Render the view to a file, off screen. The only way to look at the panel
// as an image: it can't be screenshotted — it's cut out of capture.
if let i = CommandLine.arguments.firstIndex(of: "--render"), i + 1 < CommandLine.arguments.count {
    _ = NSApplication.shared
    let v = NSHostingView(rootView: PrompterView(p: Prompter.shared))
    v.frame = NSRect(x: 0, y: 0, width: 620, height: 300)
    v.layoutSubtreeIfNeeded()
    let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds)!
    v.cacheDisplay(in: v.bounds, to: rep)
    try! rep.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1]))
    exit(0)
}

// Logic checks without a screen or a microphone.
// `precondition`, not `assert`: assert is compiled out of release builds.
if CommandLine.arguments.contains("--selftest") {
    _ = NSApplication.shared
    let p = Prompter.shared

    // Layout: text must not shrink to the window height, or there's nothing to scroll.
    p.text = String(repeating: "A line of talking points about the product\n", count: 40)
    let v = NSHostingView(rootView: PrompterView(p: p))
    v.frame = NSRect(x: 0, y: 0, width: 620, height: 300)
    v.layoutSubtreeIfNeeded()
    let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds)!
    v.cacheDisplay(in: v.bounds, to: rep)
    precondition(p.contentHeight > p.viewHeight * 3,
                 "text clipped to window height: contentHeight = \(p.contentHeight)")
    print("✓ layout: \(Int(p.contentHeight))pt of text in a \(Int(p.viewHeight))pt window")

    // Scrolling: never past the top or the bottom.
    p.scroll(by: -500)
    precondition(p.offset == 0, "scrolled above the top")
    p.scroll(by: 100)
    precondition(p.offset == 100, "scrolling doesn't move")
    p.scroll(by: 99_999)
    precondition(p.offset > 0 && p.offset < p.contentHeight, "scrolled into the void: \(p.offset)")
    let bottom = p.offset
    p.scroll(by: 1000)
    precondition(p.offset == bottom, "bottom edge doesn't hold")
    p.toTop()
    precondition(p.offset == 0 && !p.isRunning, "to-top didn't reset scrolling")
    print("✓ scrolling: both edges hold, to-top works")

    // Several files: pitch and Q&A, switching keeps your place.
    let dir = NSTemporaryDirectory()
    let pitch = URL(fileURLWithPath: dir + "pitch.md")
    let qa = URL(fileURLWithPath: dir + "qa.md")
    try! "# Pitch\n\n- point one\n- point two".write(to: pitch, atomically: true, encoding: .utf8)
    try! "# Q&A\n\n- how much\n- where is the data".write(to: qa, atomically: true, encoding: .utf8)

    let before = p.docs.count
    p.load(pitch)
    p.load(qa)
    precondition(p.docs.count == before + 2, "second file didn't open as its own tab")
    precondition(p.text.contains("where is the data"), "wrong file shown after loading")

    let pitchIndex = p.docs.firstIndex { $0.name == "pitch" }!
    let qaIndex = p.docs.firstIndex { $0.name == "qa" }!
    p.select(pitchIndex)
    precondition(p.text.contains("point two"), "switching didn't change the text")
    p.scroll(by: 150)
    let place = p.offset
    precondition(place > 0, "nothing to scroll — the place check is meaningless")
    p.select(qaIndex)
    precondition(p.offset == 0, "another file's scroll position leaked over")
    p.select(pitchIndex)
    precondition(p.offset == place, "returned to the wrong place: \(p.offset) instead of \(place)")
    print("✓ several files: switching remembers the place in each")

    // Reopening the same file refreshes its tab instead of adding a new one.
    p.load(pitch)
    precondition(p.docs.count == before + 2, "reopening created a duplicate tab")
    print("✓ reopening doesn't duplicate tabs")

    p.select(pitchIndex); p.closeCurrent()
    p.select(p.docs.firstIndex { $0.name == "qa" }!); p.closeCurrent()
    precondition(p.docs.count == before, "closing a file didn't remove its tab")
    print("✓ closing a file")

    // Font size: the knob never goes unreadable either way.
    p.setFont(2); precondition(p.fontSize == 12, "font went below 12")
    p.setFont(200); precondition(p.fontSize == 64, "font went above 64")
    p.setFont(22)
    print("✓ font size stays within 12…64")

    // Updates: version comparison must be numeric, not alphabetical.
    precondition(Updater.isNewer("v1.10.0", than: "1.9.2"), "1.10 not newer than 1.9")
    precondition(!Updater.isNewer("v1.2.0", than: "1.2.0"), "same version counted as newer")
    precondition(!Updater.isNewer("1.1.9", than: "1.2.0"), "older version counted as newer")
    print("✓ update version comparison")

    let g = VoiceGate()
    let fmt = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!

    func feed(_ amplitude: Float, blocks: Int) {
        for _ in 0..<blocks {
            let b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: 1024)!
            b.frameLength = 1024
            for i in 0..<1024 {
                b.floatChannelData![0][i] = amplitude * sin(Float(i) * 0.3)
            }
            g.consume(b)
        }
    }

    feed(0.0005, blocks: 200)                     // quiet room
    precondition(!g.isSpeaking, "silence taken for speech")
    feed(0.15, blocks: 5)                         // start talking
    precondition(g.isSpeaking, "speech not heard")
    feed(0.15, blocks: 300)                       // keep talking
    precondition(g.isSpeaking, "gate closed mid-speech: floor crept up to the voice")
    feed(0.0005, blocks: 5)                       // short pause between words
    precondition(g.isSpeaking, "text stopped in a pause between words")
    feed(0.0005, blocks: 30)                      // stop talking
    precondition(!g.isSpeaking, "gate didn't close after speech")
    print("✓ voice gate: silent — stops, talking — moves, pauses don't break it")
    print("\nEverything checkable without a screen or a microphone is fine.")
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = AppState.shared
app.run()
