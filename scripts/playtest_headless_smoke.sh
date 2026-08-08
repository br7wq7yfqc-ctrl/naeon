#!/bin/bash
set -eu
ROOT="$HOME/Documents/naeon"
export PATH="$HOME/bin:$HOME/Applications/Godot.app/Contents/MacOS:$PATH"
GODOT=godot
if ! command -v godot >/dev/null 2>&1; then
  GODOT="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
fi
echo "[playtest] using $GODOT"
"$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/world/OpenSpace.tscn --quit-after 12 > /tmp/pt_os.log 2>&1 || true
echo OS_ERR=$(grep -c 'SCRIPT ERROR' /tmp/pt_os.log || true)
"$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/test/TestArena.tscn --quit-after 6 > /tmp/pt_ta.log 2>&1 || true
echo TA_ERR=$(grep -c 'SCRIPT ERROR' /tmp/pt_ta.log || true)
grep -E 'SurfaceWater|CaveInterior|SurfaceFauna|SCRIPT ERROR' /tmp/pt_os.log | head -20 || true
