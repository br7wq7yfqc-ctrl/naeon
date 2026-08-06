# NAEON — Mac installer & auto-update

## For players

1. Open `NAEON-*-mac.dmg`
2. Double-click **Install NAEON.command** (or drag `NAEON.app` → Applications)
3. First launch: System Settings → Privacy → allow if blocked, or right-click → Open
4. App lives in `~/Applications/NAEON.app`

## For developers (build release)

```bash
cd ~/Documents/naeon
# bump VERSION first
echo 0.1.1 > VERSION
./tools/mac/build_release.sh
```

Outputs:
- `dist/NAEON.app`
- `dist/NAEON-<ver>-mac.zip` (auto-update payload)
- `dist/NAEON-<ver>-mac.dmg` (installer disk image)
- `dist/latest.json` (manifest)

Uploads (if rclone `neon` remote OK):
- `s3://neon/releases/mac/…`

## Auto-update

`AutoUpdater` autoload reads:

```
https://storage.yandexcloud.net/neon/releases/mac/latest.json
```

**Bucket ACL:** grant **public read** on prefix `releases/mac/` (or the whole public releases path) so clients can fetch without keys.

Manifest fields: `version`, `url`, `sha256`, `notes`.

On newer version: signal `update_available` → download zip → install to `~/Applications/NAEON.app`.

## Codesigning / Notarization

Current builds use **ad-hoc** signature (`codesign -s -`) for local/dev.
For public distribution: Apple Developer ID + notarization (set in `export_presets.cfg`).

## Version

Single source: repo root `VERSION` + `AutoUpdater.CURRENT_VERSION` + export preset (stamped by build script).
