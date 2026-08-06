#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
VERSION="$(tr -d '[:space:]' < VERSION)"
GODOT="${GODOT:-$HOME/Applications/Godot.app/Contents/MacOS/godot}"
DIST="$ROOT/dist"
APP="$DIST/NAEON.app"
ZIP="$DIST/NAEON-${VERSION}-mac.zip"
DMG="$DIST/NAEON-${VERSION}-mac.dmg"
STAGE="$DIST/dmg_stage"

echo "=== NAEON Mac release $VERSION ==="
mkdir -p "$DIST"
rm -rf "$APP" "$ZIP" "$DMG" "$STAGE"

python3 - << PY
from pathlib import Path
import re
ver = Path("VERSION").read_text().strip()
p = Path("godot/export_presets.cfg")
t = p.read_text()
t = re.sub(r'application/short_version="[^"]*"', f'application/short_version="{ver}"', t)
t = re.sub(r'application/version="[^"]*"', f'application/version="{ver}"', t)
p.write_text(t)
au = Path("godot/scripts/autoload/AutoUpdater.gd")
if au.exists():
    au.write_text(re.sub(r'const CURRENT_VERSION := "[^"]*"', f'const CURRENT_VERSION := "{ver}"', au.read_text()))
print("stamped", ver)
PY

echo "-> Exporting..."
"$GODOT" --headless --path "$ROOT/godot" --export-release "macOS" "$APP" 2>&1 | tail -50

if [ ! -d "$APP" ]; then
  echo "EXPORT FAILED"
  exit 1
fi

codesign --force --deep --sign - "$APP" 2>/dev/null || true
xattr -cr "$APP" 2>/dev/null || true

echo "-> Bundling assets..."
RES_ASSETS="$APP/Contents/Resources/assets"
mkdir -p "$RES_ASSETS"
if [ -d "$ROOT/assets" ]; then
  rsync -a --delete --exclude 'mac_smoke' "$ROOT/assets/" "$RES_ASSETS/"
fi
codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "-> Zip + DMG..."
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/NAEON.app"
ln -sf /Applications "$STAGE/Applications"

cat > "$STAGE/Install NAEON.command" << 'INST'
#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$DIR/NAEON.app"
if [ ! -d "$SRC" ]; then
  osascript -e 'display alert "NAEON" message "NAEON.app not found." as critical'
  exit 1
fi
if [ -w /Applications ]; then DEST="/Applications/NAEON.app"
else mkdir -p "$HOME/Applications"; DEST="$HOME/Applications/NAEON.app"; fi
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
codesign --force --deep --sign - "$DEST" 2>/dev/null || true
if [ -d "$DEST/Contents/Resources/assets" ]; then
  mkdir -p "$HOME/Library/Application Support/NAEON"
  rsync -a "$DEST/Contents/Resources/assets/" "$HOME/Library/Application Support/NAEON/assets/"
fi
open "$DEST"
osascript -e "display notification \"Installed $DEST\" with title \"NAEON\""
echo "Installed -> $DEST"
INST
chmod +x "$STAGE/Install NAEON.command"

cat > "$STAGE/README.txt" << RDM
NAEON ${VERSION}
================
1. Drag NAEON.app to Applications (or Install NAEON.command)
2. Right-click -> Open if blocked
Version ${VERSION} | assets bundled
RDM

hdiutil create -volname "NAEON ${VERSION}" -srcfolder "$STAGE" -ov -format UDZO -imagekey zlib-level=9 "$DMG"
hdiutil verify "$DMG" | tail -3

SHA=$(shasum -a 256 "$ZIP" | awk '{print $1}')
SIZE=$(stat -f%z "$ZIP")
cat > "$DIST/latest.json" << JSON
{
  "version": "$VERSION",
  "platform": "macOS",
  "url": "https://storage.yandexcloud.net/neon/releases/mac/NAEON-${VERSION}-mac.zip",
  "dmg_url": "https://storage.yandexcloud.net/neon/releases/mac/NAEON-${VERSION}-mac.dmg",
  "sha256": "$SHA",
  "size": $SIZE,
  "notes": "NAEON $VERSION bundled assets",
  "released_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON

if command -v rclone >/dev/null; then
  rclone copy "$ZIP" neon:neon/releases/mac/ 2>&1 | tail -4
  rclone copy "$DMG" neon:neon/releases/mac/ 2>&1 | tail -4
  rclone copy "$DIST/latest.json" neon:neon/releases/mac/ 2>&1 | tail -2
fi

# Desktop: remove old, place new with unmistakable names
rm -f "$HOME/Desktop/NAEON-0.1.0-mac.dmg" \
      "$HOME/Desktop/NAEON-Installer.dmg" \
      "$HOME/Desktop/NAEON-0.1.0-Installer.dmg" 2>/dev/null || true
cp -f "$DMG" "$HOME/Desktop/NAEON-${VERSION}-Installer.dmg"
cp -f "$DMG" "$HOME/Desktop/NAEON-Installer.dmg"
# Verify Desktop copy is full-size (partial copies confused players)
DESK="$HOME/Desktop/NAEON-${VERSION}-Installer.dmg"
SRC_SZ=$(stat -f%z "$DMG")
DST_SZ=$(stat -f%z "$DESK")
if [ "$SRC_SZ" != "$DST_SZ" ]; then
  echo "ERROR: Desktop copy size mismatch $DST_SZ vs $SRC_SZ — recopying"
  rm -f "$DESK"
  ditto "$DMG" "$DESK"
fi
if [ "$DST_SZ" -lt 100000000 ]; then
  echo "ERROR: Desktop DMG too small ($DST_SZ) — abort"
  exit 1
fi
cp -f "$DMG" "$HOME/Downloads/NAEON-${VERSION}-Installer.dmg" 2>/dev/null || true

# touch to refresh Finder
touch "$HOME/Desktop/NAEON-${VERSION}-Installer.dmg"
open -R "$HOME/Desktop/NAEON-${VERSION}-Installer.dmg"
open "$HOME/Desktop/NAEON-${VERSION}-Installer.dmg"

echo "=== DONE ==="
ls -lah "$DMG" "$HOME/Desktop/NAEON-${VERSION}-Installer.dmg" "$HOME/Desktop/NAEON-Installer.dmg"
du -sh "$APP" "$APP/Contents/Resources/assets" 2>/dev/null || true
stat -f "%Sm %N" -t "%Y-%m-%d %H:%M" "$HOME/Desktop/NAEON-${VERSION}-Installer.dmg"
