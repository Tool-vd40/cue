import SwiftUI

private struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct PrompterView: View {
    @ObservedObject var p: Prompter
    /// The panel stays bare until hovered: notes visible, chrome out of the way.
    @State private var hovering = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.78)

            GeometryReader { geo in
                (p.text.isEmpty ? Text("Open a file, or copy your notes and press ⌃⌥V") : Text(verbatim: p.text))
                    .font(.system(size: p.fontSize, weight: .medium, design: .rounded))
                    .lineSpacing(p.fontSize * 0.3)
                    .foregroundStyle(.white)
                    .frame(width: geo.size.width - 32, alignment: .leading)
                    // Without this the text shrinks to the window height and gets
                    // clipped: nothing left to scroll, maxOffset drops to zero.
                    .fixedSize(horizontal: false, vertical: true)
                    .background(GeometryReader { g in
                        Color.clear.preference(key: HeightKey.self, value: g.size.height)
                    })
                    .offset(y: -p.offset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(16)
                    .onAppear { p.viewHeight = geo.size.height }
                    .onChange(of: geo.size.height) { p.viewHeight = $0 }
            }
            .clipped()
            .onPreferenceChange(HeightKey.self) { p.contentHeight = $0 }

            if hovering {
                VStack(spacing: 6) {
                    if p.docs.count > 1 { tabs }
                    controls
                }
                .padding(.bottom, 8)
            }
        }
        .onHover { hovering = $0 }
    }

    private var controls: some View {
        HStack(spacing: 14) {
            btn(p.isRunning ? "pause.fill" : "play.fill") { p.toggleRun() }
            btn(p.voiceMode ? "mic.fill" : "mic.slash") { p.toggleVoice() }
                .foregroundStyle(p.voiceMode ? Color.green : .white.opacity(0.85))
            btn("arrow.up.to.line") { p.toTop() }
            Divider().frame(height: 12)
            btn("textformat.size.smaller") { p.setFont(p.fontSize - 2) }
            btn("textformat.size.larger") { p.setFont(p.fontSize + 2) }
            Divider().frame(height: 12)
            btn("doc.on.clipboard") { p.pasteFromClipboard() }
            btn("folder") { p.openFiles() }
            if p.docs.count > 1 { btn("chevron.left.chevron.right") { p.select((p.current + 1) % p.docs.count) } }
            btn("xmark") { AppState.shared.toggle() }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.black.opacity(0.75), in: Capsule())
    }

    /// Open files. Pitch, Q&A, numbers — switch with a click,
    /// or faster on a call from the keyboard: ⌃⌥1…9.
    private var tabs: some View {
        HStack(spacing: 6) {
            ForEach(Array(p.docs.enumerated()), id: \.offset) { i, doc in
                Button { p.select(i) } label: {
                    Text(verbatim: "\(i + 1)  \(doc.name)")
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(i == p.current ? .white.opacity(0.22) : .black.opacity(0.75),
                                    in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(i == p.current ? 1 : 0.6))
            }
        }
    }

    private func btn(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.85))
    }
}
