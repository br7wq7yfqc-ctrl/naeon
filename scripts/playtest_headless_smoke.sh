#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export PATH="$HOME/bin:$HOME/Applications/Godot.app/Contents/MacOS:/usr/local/bin:$PATH"
GODOT=godot
if ! command -v godot >/dev/null 2>&1; then
  if [ -x "$HOME/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
  elif [ -x /usr/local/bin/godot ]; then
    GODOT=/usr/local/bin/godot
  fi
fi
echo "[playtest] using $GODOT root=$ROOT"
"$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/world/OpenSpace.tscn --quit-after 12 > /tmp/pt_os.log 2>&1 || true
echo OS_ERR=$(grep -c 'SCRIPT ERROR' /tmp/pt_os.log || true)
"$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/test/TestArena.tscn --quit-after 6 > /tmp/pt_ta.log 2>&1 || true
echo TA_ERR=$(grep -c 'SCRIPT ERROR' /tmp/pt_ta.log || true)
grep -E 'SurfaceWater|CaveInterior|SurfaceFauna|SCRIPT ERROR|CanonPlates|PadAmbientLife|AbilitySystem' /tmp/pt_os.log | head -20 || true
grep -E 'SCRIPT ERROR|CanonPlates|TestArena' /tmp/pt_ta.log | head -20 || true
