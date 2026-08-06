#!/usr/bin/env bash
# Watch local assets/ folder and sync changes to Yandex Object Storage (neon:dev)
# Requires: rclone + fswatch (macOS) or inotifywait (Linux)

set -euo pipefail

LOCAL_DIR="${LOCAL_ASSETS_PATH:-./assets}"
REMOTE="neon:dev"
DEBOUNCE_SECONDS=8

echo "Watching ${LOCAL_DIR} → ${REMOTE}"
echo "Press Ctrl+C to stop"

if ! command -v rclone &> /dev/null; then
  echo "rclone not found. Install it first."
  exit 1
fi

mkdir -p "${LOCAL_DIR}"

sync_now() {
  echo "$(date '+%H:%M:%S') → Syncing to bucket..."
  rclone sync "${LOCAL_DIR}" "${REMOTE}" \
    --exclude ".DS_Store" \
    --exclude "*.tmp" \
    --exclude "Thumbs.db" \
    --exclude ".git/" \
    --progress
  echo "$(date '+%H:%M:%S') ✓ Sync finished"
}

# Initial sync
sync_now

if command -v fswatch &> /dev/null; then
  # macOS
  fswatch -o "${LOCAL_DIR}" | while read -r; do
    sleep "${DEBOUNCE_SECONDS}"
    sync_now
  done
elif command -v inotifywait &> /dev/null; then
  # Linux
  while inotifywait -r -e modify,create,delete,move "${LOCAL_DIR}"; do
    sleep "${DEBOUNCE_SECONDS}"
    sync_now
  done
else
  echo "No file watcher found (fswatch or inotifywait). Falling back to periodic sync every 60s."
  while true; do
    sleep 60
    sync_now
  done
fi
