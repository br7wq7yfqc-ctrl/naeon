#!/bin/bash
# NAEON Mac installer — copies NAEON.app to ~/Applications and removes quarantine
set -euo pipefail
cd "$(dirname "$0")"
SRC=""
if [ -d "./NAEON.app" ]; then
  SRC="$(pwd)/NAEON.app"
elif [ -d "../dist/NAEON.app" ]; then
  SRC="$(cd ../dist && pwd)/NAEON.app"
elif [ -d "/Volumes/NAEON/NAEON.app" ]; then
  SRC="/Volumes/NAEON/NAEON.app"
else
  # same folder as this script when inside DMG
  for c in "$(dirname "$0")/NAEON.app" "$(pwd)/../NAEON.app"; do
    [ -d "$c" ] && SRC="$c" && break
  done
fi

if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
  osascript -e 'display alert "NAEON Installer" message "NAEON.app not found next to this installer." as critical'
  exit 1
fi

DEST_DIR="${HOME}/Applications"
mkdir -p "$DEST_DIR"
DEST="${DEST_DIR}/NAEON.app"
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
# ad-hoc sign for local run
codesign --force --deep --sign - "$DEST" 2>/dev/null || true

# Dock / open
open "$DEST"
osascript -e 'display notification "NAEON installed to ~/Applications" with title "NAEON"'
echo "Installed → $DEST"
