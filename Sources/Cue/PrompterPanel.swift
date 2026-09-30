import AppKit
import SwiftUI

/// Floating panel with the notes.
///
/// The whole point is `sharingType = .none`. macOS cuts windows with this
/// flag out of screen capture, whether a single window or the whole screen
/// is shared. Zoom, Meet, Teams, QuickTime all go through system capture,
/// so nobody but you sees the panel.
final class PrompterPanel: NSPanel {
    init() {
        let saved = UserDefaults.standard.string(forKey: "frame")
        let size = NSSize(width: 620, height: 260)

        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            // .nonactivatingPanel — the panel doesn't steal focus: during
            // a call Zoom stays active, not us.
            styleMask: [.nonactivatingPanel, .borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // The only way to get the panel into a screenshot is to drop this flag.
        // Handy when you need to show what it looks like.
        sharingType = ProcessInfo.processInfo.environment["CUE_VISIBLE"] == nil ? .none : .readOnly

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isReleasedWhenClosed = false

        let root = NSView(frame: NSRect(origin: .zero, size: size))
        root.wantsLayer = true
        root.layer?.cornerRadius = 14
        root.layer?.cornerCurve = .continuous
        root.layer?.masksToBounds = true

        let hosting = NSHostingView(rootView: PrompterView(p: Prompter.shared))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: root.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: root.trailingAnchor),
        ])
        contentView = root

        if let saved { setFrame(NSRectFromString(saved), display: false) } else { placeUnderCamera() }

        catchScrollWheel()
    }

    /// Mouse wheel and trackpad scroll the text.
    ///
    /// Caught with an event monitor, not `scrollWheel` on the view:
    /// `NSHostingView` installs its own recognizers and the event never
    /// reaches the backing view. The monitor sees it first.
    private var monitor: Any?

    private func catchScrollWheel() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, event.window === self, self.isVisible else { return event }
            Prompter.shared.stop()
            Prompter.shared.scroll(by: -event.scrollingDeltaY * (event.hasPreciseScrollingDeltas ? 1 : 6))
            return nil
        }
    }

    /// Default spot is top center, under the camera: reading the text
    /// looks like looking into the camera.
    private func placeUnderCamera() {
        guard let screen = NSScreen.main else { return }
        let v = screen.visibleFrame
        setFrameOrigin(NSPoint(x: v.midX - frame.width / 2, y: v.maxY - frame.height))
    }

    func saveFrame() {
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: "frame")
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
