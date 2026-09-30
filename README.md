# Cue

A teleprompter for video calls: your talking points float above every window,
and nobody you share your screen with can see them.

**[⬇ Download Cue for macOS](https://github.com/Tool-vd40/cue/releases/latest/download/Cue.dmg)** · macOS 13+ · [all releases](../../releases) · [Русская версия](README.ru.md)

The panel sets `NSWindow.sharingType = .none`, so macOS cuts it out of screen
capture. Zoom, Meet, Teams, QuickTime recording and system screenshots all go
through that capture, so the panel doesn't show up in them.

## Install

1. [Download Cue.dmg](https://github.com/Tool-vd40/cue/releases/latest/download/Cue.dmg).
2. Open it and drag **Cue** into **Applications**.
3. Launch Cue from Applications.

Cue lives in the menu bar (a lines-of-text icon at the top of the screen),
there's no Dock icon. Requires macOS 13 or later.

### "Apple could not verify Cue is free of malware"

On first launch macOS shows this warning. It's expected: Cue is open source
but not notarized by Apple (that requires a paid Apple Developer account).
macOS shows this for every app downloaded from the internet without
notarization. You only need to allow it once.

**macOS 15 Sequoia and later**

1. In the warning, click **Done** (not "Move to Trash").
2. Open **System Settings → Privacy & Security** and scroll down.
3. Next to "Cue was blocked to protect your Mac", click **Open Anyway**.
4. Confirm with your password or Touch ID, then click **Open Anyway** again.

**macOS 13 Ventura and 14 Sonoma**

1. In Finder, open **Applications**.
2. Right-click (or Control-click) **Cue** → **Open**.
3. Click **Open** in the dialog.

**Any version, via Terminal**

    xattr -dr com.apple.quarantine /Applications/Cue.app

This removes the "downloaded from the internet" flag, the one that triggers
the warning.

After that Cue opens normally, and in-app updates install without the warning.

## Updates

Cue checks GitHub Releases at launch and offers to install a newer version.
Manually: menu bar → Check for Updates…

## Hotkeys

| | |
|---|---|
| ⌃⌥P | show / hide the panel |
| ⌃⌥V | paste notes from the clipboard |
| ⌃⌥↑ ⌃⌥↓ | scroll |
| ⌃⌥Space | auto-scroll |
| ⌃⌥1 … ⌃⌥9 | switch between open files |

If a shortcut is taken by another app, Cue says so in the first line of its
menu — Carbon refuses silently, otherwise the hotkey just "doesn't work".

The mouse wheel scrolls the text, the panel drags from anywhere and resizes
from the edges. Hover to reveal buttons: font size, to top, paste, open files,
next file, hide. Edit the text from the menu bar → Edit Text…

## Several files

Open Files… takes as many as you like: pitch, Q&A, numbers. Open files show as
tabs above the buttons on hover; switch with a click or ⌃⌥1…9. Each file keeps
its own scroll position. Reopening a file refreshes its tab instead of adding
another. Close one from the menu bar → Close Current File.

## Voice-paced scrolling

The mic button on the panel (or menu bar → Voice-Paced Scrolling): the text
moves while you talk and stops while you're silent. There's no speech
recognition — people paraphrase their notes anyway.

Mic permission is requested when you switch this on, not at launch. The
threshold adapts to the room noise; if it triggers on the air conditioner or
misses quiet speech, tune `sensitivity` in `VoiceGate.swift`.

## Build

    ./scripts/make-dmg.sh             # dist/Cue.app, Cue.dmg, Cue.zip
    .build/release/Cue --selftest     # logic checks: layout, scrolling, files, font, updates, voice gate
    swift scripts/check-invisible.swift   # with Cue running: panel is on screen

CI builds and runs the self-test on macOS 14, 15 and 26 for every push.

## Release

    git tag v1.1.0 && git push origin v1.1.0

CI builds `Cue.zip` and `Cue.dmg` and publishes the release; installed copies
pick it up on the next launch.

---

Keywords: teleprompter for Mac, hidden teleprompter for Zoom, Google Meet and
Microsoft Teams, speaker notes invisible to screen sharing, interview cheat
sheet, presentation prompter, macOS menu bar app, суфлёр для Mac.
