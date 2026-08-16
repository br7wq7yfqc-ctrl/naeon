#!/usr/bin/env bash
# Copy completed Tripo inbox GLBs → s3://neon/dev/tripo/<slug>/
#
# Safe while image-to-model is still running:
#   - copy only (never delete, never rclone sync)
#   - skip folders without model.glb
#   - do not create Tripo tasks
#
# Usage (Mac):
#   ./scripts/assets/harvest_tripo_inbox.sh
#   ./scripts/assets/harvest_tripo_inbox.sh --watch   # every 60s until Ctrl+C

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC1091
[ -f "$ROOT/.env" ] && set -a && source "$ROOT/.env" && set +a

INBOX="${TRIP_INBOX:-$ROOT/pipeline/inbox}"
REMOTE="${TRIP_REMOTE:-neon:neon/dev/tripo}"
LOG="$ROOT/logs/tripo_harvest.jsonl"
INTERVAL="${HARVEST_INTERVAL:-60}"
WATCH=0
[ "${1:-}" = "--watch" ] && WATCH=1

mkdir -p "$(dirname "$LOG")"

have_rclone() { command -v rclone >/dev/null 2>&1; }
have_aws() { command -v aws >/dev/null 2>&1; }

log_json() {
  printf '%s\n' "$1" | tee -a "$LOG"
}

upload_one() {
  local slug="$1" src="$2"
  if have_rclone; then
    rclone copy "$src" "$REMOTE/$slug" \
      --include "model.glb" \
      --include "meta.json" \
      --include "*.webp" \
      --include "*.png" \
      --include "*.jpg" \
      --exclude ".DS_Store"
  elif have_aws; then
    aws s3 cp "$src/model.glb" "s3://neon/dev/tripo/$slug/model.glb" \
      --endpoint-url "${YC_STORAGE_ENDPOINT:-https://storage.yandexcloud.net}" \
      --profile "${AWS_PROFILE:-neon}"
    [ -f "$src/meta.json" ] && aws s3 cp "$src/meta.json" "s3://neon/dev/tripo/$slug/meta.json" \
      --endpoint-url "${YC_STORAGE_ENDPOINT:-https://storage.yandexcloud.net}" \
      --profile "${AWS_PROFILE:-neon}"
  else
    echo "need rclone or aws cli" >&2
    return 2
  fi
}

pass_once() {
  local found=0 uploaded=0 skipped=0
  [ -d "$INBOX" ] || { echo "no inbox: $INBOX"; return 0; }
  for dir in "$INBOX"/*; do
    [ -d "$dir" ] || continue
    local slug
    slug="$(basename "$dir")"
    [ "$slug" = "." ] && continue
    found=$((found + 1))
    if [ ! -f "$dir/model.glb" ]; then
      skipped=$((skipped + 1))
      continue
    fi
    if upload_one "$slug" "$dir"; then
      uploaded=$((uploaded + 1))
      log_json "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"uploaded\",\"asset\":\"$slug\",\"bytes\":$(wc -c < "$dir/model.glb")}"
    else
      log_json "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"fail\",\"asset\":\"$slug\"}"
    fi
  done
  echo "inbox=$found uploaded=$uploaded pending_no_glb=$skipped → $REMOTE"
}

if ! have_rclone && ! have_aws; then
  echo "install rclone (brew install rclone) or awscli first" >&2
  exit 1
fi

echo "harvest $INBOX → $REMOTE  (copy only, batch stays running)"
pass_once
if [ "$WATCH" -eq 1 ]; then
  echo "watch every ${INTERVAL}s — Ctrl+C to stop"
  while true; do
    sleep "$INTERVAL"
    pass_once
  done
fi
