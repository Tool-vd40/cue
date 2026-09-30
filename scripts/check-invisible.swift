// The check the whole thing exists for.
//
// A real screen capture can't be taken from here: without Screen Recording
// permission macOS returns bare wallpaper, and the image would "prove" even a
// visible panel invisible. So this checks only what needs no permission: the
// panel is on screen and it's ours. The real test is ⌘⇧4 by hand, see output.
import CoreGraphics
import Foundation

let all = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let ours = all
    .filter { ($0[kCGWindowOwnerName as String] as? String) == "Cue" }
    .filter { ($0[kCGWindowLayer as String] as? Int) != 25 }  // skip the menu bar item

guard let w = ours.first else {
    print("✗ panel not found — launch Cue and show it: ⌃⌥P")
    exit(1)
}
let b = w[kCGWindowBounds as String] as! [String: CGFloat]
assert(b["Width"]! > 100 && b["Height"]! > 100, "panel collapsed")
print("✓ panel on screen: \(Int(b["Width"]!))×\(Int(b["Height"]!)) at (\(Int(b["X"]!)), \(Int(b["Y"]!)))")
print("")
print("Now check by eye — the panel must be absent both times:")
print("  1) ⌘⇧4 around the panel, look at the screenshot on the desktop")
print("  2) a Zoom or Meet call with yourself, share screen")
