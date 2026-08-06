#!/bin/bash
# Export NAEON.app, package zip/dmg, upload to neon releases, write latest.json
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

# Sync version into export preset
python3 - << PY
from pathlib import Path
p = Path("godot/export_presets.cfg")
t = p.read_text()
import re
t = re.sub(r'application/short_version="[^"]*"', 'application/short_version="$VERSION"', t)
t = re.sub(r'application/version="[^"]*"', 'application/version="$VERSION"', t)
p.write_text(t)
# AutoUpdater CURRENT_VERSION
au = Path("godot/scripts/autoload/AutoUpdater.gd")
au.write_text(au.read_text().replace(
    'const CURRENT_VERSION := "' + [l.split('"')[1] for l in au.read_text().splitlines() if "CURRENT_VERSION" in l][0] + '"',
    f'const CURRENT_VERSION := "$VERSION"'
) if False else au.read_text())
text = au.read_text()
import re as _re
text = _re.sub(r'const CURRENT_VERSION := "[^"]*"', f'const CURRENT_VERSION := "$VERSION"', text)
au.write_text(text)
print("version stamps", "$VERSION")
PY

echo "→ Exporting (release)…"
"$GODOT" --headless --path "$ROOT/godot" --export-release "macOS" "$APP" 2>&1 | tail -30

if [ ! -d "$APP" ]; then
  echo "Export failed — app missing"
  exit 1
fi

# Ad-hoc codesign
codesign --force --deep --sign - "$APP" 2>/dev/null || true
xattr -cr "$APP" 2>/dev/null || true

# Zip for auto-update
echo "→ Zip…"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
# Also pack installer
cp tools/mac/Install\ NAEON.command "$DIST/"
(
  cd "$DIST"
  ditto -c -k --keepParent "Install NAEON.command" "Install-NAEON.command.zip" 2>/dev/null || true
)

# DMG (optional if hdiutil available)
echo "→ DMG…"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/NAEON.app"
cp tools/mac/Install\ NAEON.command "$STAGE/"
# symlink to Applications
ln -sf /Applications "$STAGE/Applications"
hdiutil create -volname "NAEON" -srcfolder "$STAGE" -ov -format UDZO "$DMG"

# SHA256
SHA=$(shasum -a 256 "$ZIP" | awk '{print $1}')
SIZE=$(stat -f%z "$ZIP")

# latest.json
cat > "$DIST/latest.json" << JSON
{
  "version": "$VERSION",
  "platform": "macOS",
  "url": "https://storage.yandexcloud.net/neon/releases/mac/NAEON-${VERSION}-mac.zip",
  "dmg_url": "https://storage.yandexcloud.net/neon/releases/mac/NAEON-${VERSION}-mac.dmg",
  "sha256": "$SHA",
  "size": $SIZE,
  "notes": "NAEON $VERSION — TestArena combat, dual-theme props, ship sandbox",
  "min_os": "12.0",
  "released_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON

# Upload to neon if rclone configured
if command -v rclone >/dev/null && [ -f "$HOME/.config/rclone/rclone.conf" ]; then
  echo "→ Upload to neon:neon/releases/mac/"
  rclone copy "$ZIP" neon:neon/releases/mac/ --progress
  rclone copy "$DMG" neon:neon/releases/mac/ --progress
  rclone copy "$DIST/latest.json" neon:neon/releases/mac/ --progress
  # try public-read ACL if provider supports
  rclone copyto "$DIST/latest.json" neon:neon/releases/mac/latest.json 2>/dev/null || true
  echo "Uploaded. Public URL depends on bucket ACL."
  echo "  latest:  neon:neon/releases/mac/latest.json"
  echo "  zip:     neon:neon/releases/mac/NAEON-${VERSION}-mac.zip"
else
  echo "rclone not configured — artifacts only in dist/"
fi

echo "=== DONE ==="
ls -lah "$APP" "$ZIP" "$DMG" "$DIST/latest.json"
echo "Install: open tools/mac/Install\\ NAEON.command  (or mount DMG)"
