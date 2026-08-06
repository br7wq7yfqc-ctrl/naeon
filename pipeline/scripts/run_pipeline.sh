#!/usr/bin/env bash
# NAEON end-to-end asset pipeline: Tripo → process → assets → optional rclone sync
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi

if [[ -f "$ROOT/.venv/bin/activate" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/.venv/bin/activate"
fi

PROMPT="${1:-futuristic cybernex canine robot scout, dark neon, low poly game ready}"
NAME="${2:-canine_scout_$(date +%Y%m%d_%H%M%S)}"
PRIORITY="${3:-B}"

echo "=== NAEON pipeline ==="
echo "name=$NAME priority=$PRIORITY"
echo "prompt=$PROMPT"

python pipeline/scripts/generate_tripo.py --prompt "$PROMPT" --name "$NAME" --priority "$PRIORITY"
GLB="pipeline/inbox/$NAME/model.glb"
if [[ ! -f "$GLB" ]]; then
  echo "No model.glb — stopping after generation step"
  exit 2
fi

python pipeline/scripts/process_asset.py --input "$GLB" --name "$NAME"

if command -v rclone >/dev/null 2>&1 && rclone listremotes 2>/dev/null | grep -q '^neon:'; then
  echo "→ rclone sync assets → neon:neon/dev"
  rclone sync "$ROOT/assets" neon:neon/dev --progress
else
  echo "(skip rclone — configure remote 'neon' to enable bucket sync)"
fi

echo "✓ pipeline complete for $NAME"
