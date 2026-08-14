#!/bin/bash
## Launch NAEON for GUI playtest. Uses gl_compatibility on software GL.
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GODOT="${GODOT:-godot}"
EXTRA=()
ADAPTER="$(DISPLAY="${DISPLAY:-:1}" "$GODOT" --display-driver x11 --quit-after 1 --path "$ROOT/godot" 2>/dev/null | true || true)"
# Prefer compatibility on this Linux VM / llvmpipe.
if [ -z "${NAEON_RENDER:-}" ]; then
  EXTRA+=(--rendering-method gl_compatibility --rendering-driver opengl3)
fi
exec "$GODOT" --path "$ROOT/godot" --display-driver x11 "${EXTRA[@]}" "$@"
