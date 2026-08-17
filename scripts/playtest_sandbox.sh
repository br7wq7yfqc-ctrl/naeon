#!/bin/bash
## Honest sandbox playtest. Never treats mechanics PASS as human-ready.
## Never stamps rules/25 FPS PASS on llvmpipe.
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
echo "[sandbox] using $GODOT root=$ROOT version=$($GODOT --version 2>/dev/null || echo unknown)"
echo "[sandbox] display=${DISPLAY:-none} renderer=llvmpipe-or-dummy"

"$GODOT" --headless --editor --quit-after 20 --path "$ROOT/godot" > /tmp/sb_import.log 2>&1 || true

set +e
timeout 25 "$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/ui/MainMenu.tscn --quit-after 6 > /tmp/sb_mm.log 2>&1
MM_CODE=$?
timeout 30 "$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/world/OpenSpace.tscn --quit-after 14 > /tmp/sb_os.log 2>&1
OS_CODE=$?
timeout 25 "$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/test/TestArena.tscn --quit-after 8 > /tmp/sb_ta.log 2>&1
TA_CODE=$?
timeout 90 "$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/world/OpenSpace.tscn -- --sandbox-playtest > /tmp/sb_os_probe.log 2>&1
PROBE_CODE=$?
timeout 50 "$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/world/OpenSpace.tscn -- --playtest-mechanics > /tmp/sb_mech.log 2>&1
MECH_CODE=$?
set -e

count_se() { grep -c 'SCRIPT ERROR' "$1" 2>/dev/null || true; }
count_mnull() { grep -c 'Parameter "m" is null' "$1" 2>/dev/null || true; }

echo "MM_CODE=$MM_CODE MM_ERR=$(count_se /tmp/sb_mm.log) MM_MNULL=$(count_mnull /tmp/sb_mm.log)"
echo "OS_CODE=$OS_CODE OS_ERR=$(count_se /tmp/sb_os.log) OS_MNULL=$(count_mnull /tmp/sb_os.log)"
echo "TA_CODE=$TA_CODE TA_ERR=$(count_se /tmp/sb_ta.log) TA_MNULL=$(count_mnull /tmp/sb_ta.log)"
echo "PROBE_CODE=$PROBE_CODE PROBE_ERR=$(count_se /tmp/sb_os_probe.log) PROBE_MNULL=$(count_mnull /tmp/sb_os_probe.log)"
echo "MECH_CODE=$MECH_CODE MECH_ERR=$(count_se /tmp/sb_mech.log) MECH_MNULL=$(count_mnull /tmp/sb_mech.log)"
echo "MECHANICS_IS_NOT_HUMAN_GATE=true"
echo "--- MainMenu ---"
grep -E 'SCRIPT ERROR|ERROR|MainMenu|\[Sandbox\]' /tmp/sb_mm.log | head -30 || true
echo "--- OpenSpace boot ---"
grep -E 'SCRIPT ERROR|ERROR|OpenSpace|PlanetBody|Surface|Landscape|Cave|P0|seed' /tmp/sb_os.log | head -40 || true
echo "--- TestArena ---"
grep -E 'SCRIPT ERROR|ERROR|TestArena' /tmp/sb_ta.log | head -30 || true
echo "--- Sandbox probe ---"
grep -E '\[Sandbox\]|SCRIPT ERROR|ERROR' /tmp/sb_os_probe.log | head -100 || true
echo "--- Mechanics (not a human gate) ---"
grep -E '\[Playtest\]|SCRIPT ERROR' /tmp/sb_mech.log | head -40 || true

if grep -q 'HUMAN_UNFIT' /tmp/sb_os_probe.log 2>/dev/null; then
  echo "[sandbox] probe verdict HUMAN_UNFIT (expected on llvmpipe — no FPS PASS)"
else
  echo "[sandbox] probe did not print HUMAN_UNFIT — treat as incomplete run"
fi
if grep -q '\[Playtest\] FAIL' /tmp/sb_mech.log 2>/dev/null; then
  echo "[sandbox] mechanics FAIL (honest — do not ignore)"
elif grep -q '\[Playtest\] PASS' /tmp/sb_mech.log 2>/dev/null; then
  echo "[sandbox] mechanics printed PASS — still not a human gate"
fi
echo "[sandbox] HUMAN_UNFIT — do not stamp FPS PASS on llvmpipe"
exit 0
