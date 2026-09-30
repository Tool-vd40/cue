// App icon: lines of text on a dark rounded square.
// Drawn in code — no need for an image file in the repo for one icon.
import AppKit

let out = CommandLine.arguments[1]  // .iconset folder
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

func draw(_ side: Int) -> Data {
    let s = CGFloat(side)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()
    // Margin per Apple template proportions: the icon fills ~80%.
    let pad = s * 0.1
    let rect = NSRect(x: pad, y: pad, width: s - pad * 2, height: s - pad * 2)
    let bg = NSBezierPath(roundedRect: rect, xRadius: s * 0.2, yRadius: s * 0.2)
    NSColor(calibratedWhite: 0.11, alpha: 1).setFill()
    bg.fill()

    // Four lines of "text", the last one shorter — a recognizable paragraph shape.
    let widths: [CGFloat] = [1, 0.85, 0.95, 0.55]
    let lh = rect.height * 0.085
    let gap = rect.height * 0.11
    let block = lh * 4 + gap * 3
    var y = rect.midY + block / 2 - lh
    for w in widths {
        let lineW = rect.width * 0.62 * w
        let line = NSBezierPath(roundedRect: NSRect(x: rect.midX - rect.width * 0.31,
                                                    y: y, width: lineW, height: lh),
                                xRadius: lh / 2, yRadius: lh / 2)
        NSColor.white.withAlphaComponent(0.92).setFill()
        line.fill()
        y -= lh + gap
    }
    img.unlockFocus()
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    return rep.representation(using: .png, properties: [:])!
}

for (side, name) in [(16, "16x16"), (32, "16x16@2x"), (32, "32x32"), (64, "32x32@2x"),
                     (128, "128x128"), (256, "128x128@2x"), (256, "256x256"),
                     (512, "256x256@2x"), (512, "512x512"), (1024, "512x512@2x")] {
    try! draw(side).write(to: URL(fileURLWithPath: "\(out)/icon_\(name).png"))
}
