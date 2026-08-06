#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
[ -f "$ROOT/.env" ] && set -a && source "$ROOT/.env" && set +a
DST="${LOCAL_ASSETS_PATH:-$ROOT/assets}"
mkdir -p "$DST"
echo "→ sync neon:neon/dev → $DST"
rclone sync neon:neon/dev "$DST" --progress
