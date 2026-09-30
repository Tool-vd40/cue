#!/usr/bin/env bash
# Builds dist/Cue.app from the SwiftPM target. No Xcode project needed.
# Version comes from $VERSION, else the latest git tag (v1.2.0 → 1.2.0).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)}"
VERSION="${VERSION:-0.0.0}"
APP_DIR="dist/Cue.app"

swift build -c release

rm -rf dist
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp .build/release/Cue "${APP_DIR}/Contents/MacOS/Cue"
cp -R Resources/*.lproj "${APP_DIR}/Contents/Resources/"

ICONSET="$(mktemp -d)/AppIcon.iconset"
swift scripts/make-icon.swift "${ICONSET}"
iconutil -c icns -o "${APP_DIR}/Contents/Resources/AppIcon.icns" "${ICONSET}"
rm -rf "${ICONSET%/*}"

cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Cue</string>
    <key>CFBundleDisplayName</key><string>Cue</string>
    <key>CFBundleExecutable</key><string>Cue</string>
    <key>CFBundleIdentifier</key><string>io.github.tool-vd40.cue</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key><array><string>en</string><string>ru</string></array>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <!-- Menu bar only, no Dock icon: a Dock icon would give us away on a call. -->
    <key>LSUIElement</key><true/>
    <!-- Mic is only for voice-paced scrolling and is requested when that's
         switched on. Without this key the app crashes. -->
    <key>NSMicrophoneUsageDescription</key><string>So the text moves while you talk and stops when you're silent.</string>
</dict>
</plist>
PLIST

codesign --force --sign - "${APP_DIR}"
echo "==> Built ${APP_DIR} ${VERSION}"
