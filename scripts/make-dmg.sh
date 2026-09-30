#!/usr/bin/env bash
# Builds dist/Cue.dmg (drag to Applications) and dist/Cue.zip (for in-app updates).
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build-app.sh

STAGE="$(mktemp -d)"
cp -R "dist/Cue.app" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"
# BOM so TextEdit reads the Cyrillic as UTF-8, not Mac Roman.
{ printf '\xEF\xBB\xBF'; cat scripts/how-to-open.txt; } > "${STAGE}/Как открыть Cue — How to open.txt"
hdiutil create -volname "Cue" -srcfolder "${STAGE}" -ov -format UDZO "dist/Cue.dmg" >/dev/null
rm -rf "${STAGE}"

ditto -c -k --keepParent "dist/Cue.app" "dist/Cue.zip"

echo "==> Built dist/Cue.dmg and dist/Cue.zip"
