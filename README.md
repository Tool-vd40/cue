# Cue

A teleprompter for video calls: your talking points float above every window,
and nobody you share your screen with can see them.

[Русская версия](README.ru.md)

The panel sets `NSWindow.sharingType = .none`, so macOS cuts it out of screen
capture. Zoom, Meet, Teams, QuickTime recording and system screenshots all go
through that capture, so the panel doesn't show up in them.

## Install

Download `Cue.dmg` from [Releases](../../releases/latest) and drag Cue to Applications.

Cue is ad-hoc signed, not notarized, so macOS blocks the first launch.
On macOS 15 and later: open Cue once, then System Settings → Privacy & Security →
"Open Anyway". On macOS 13–14: right-click Cue → Open → Open. Or from Terminal:

    xattr -dr com.apple.quarantine /Applications/Cue.app

Cue lives in the menu bar, there's no Dock icon. Requires macOS 13 or later.

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
