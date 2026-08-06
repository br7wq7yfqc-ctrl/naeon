#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC1091
[ -f "$ROOT/.env" ] && set -a && source "$ROOT/.env" && set +a
SRC="${LOCAL_ASSETS_PATH:-$ROOT/assets}"
echo "→ sync $SRC → neon:neon/dev"
rclone sync "$SRC" neon:neon/dev --progress
