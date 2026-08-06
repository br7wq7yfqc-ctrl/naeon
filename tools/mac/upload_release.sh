#!/bin/bash
set -euo pipefail
export PATH="${HOME}/bin:${PATH}"
ROOT="${HOME}/Documents/naeon"
VER="${1:-}"
if [ -z "$VER" ]; then
  VER=$(tr -d '[:space:]' < "${ROOT}/VERSION")
fi
cd "$ROOT"
DMG="dist/NAEON-${VER}-mac.dmg"
ZIP="dist/NAEON-${VER}-mac.zip"
LATEST="dist/latest.json"
if [ ! -f "$DMG" ]; then
  echo "Missing $DMG"; exit 1
fi
echo "Uploading NAEON $VER → neon:neon/releases/mac/"
rclone copyto "$DMG" "neon:neon/releases/mac/NAEON-${VER}-mac.dmg" --s3-no-check-bucket -v
if [ -f "$ZIP" ]; then
  rclone copyto "$ZIP" "neon:neon/releases/mac/NAEON-${VER}-mac.zip" --s3-no-check-bucket -v
fi
if [ -f "$LATEST" ]; then
  rclone copyto "$LATEST" "neon:neon/releases/mac/latest.json" --s3-no-check-bucket -v
  rclone copyto "$LATEST" "neon:neon/releases/latest.json" --s3-no-check-bucket -v
fi
rclone copyto "$DMG" "neon:neon/releases/mac/NAEON-Installer.dmg" --s3-no-check-bucket -v
echo "Listed:"
rclone lsf "neon:neon/releases/mac/" | tail -20
