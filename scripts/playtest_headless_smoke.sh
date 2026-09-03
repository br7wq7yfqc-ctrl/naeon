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
# Global class_name cache (Ability, ShipModule, …) — required on a cold checkout
"$GODOT" --headless --editor --quit-after 20 --path "$ROOT/godot" > /tmp/pt_import.log 2>&1 || true
"$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/world/OpenSpace.tscn --quit-after 12 > /tmp/pt_os.log 2>&1 || true
echo OS_ERR=$(grep -c 'SCRIPT ERROR' /tmp/pt_os.log || true)
"$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/test/TestArena.tscn --quit-after 6 > /tmp/pt_ta.log 2>&1 || true
echo TA_ERR=$(grep -c 'SCRIPT ERROR' /tmp/pt_ta.log || true)
set +e
timeout 20 "$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/test/TestArena.tscn -- --playtest-arena > /tmp/pt_ar.log 2>&1
AR_CODE=$?
set -e
if grep -q '\[Playtest\] PASS arena AR-A' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-B' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-C' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-D' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-E' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-F' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-G' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-I' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-J' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-K' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-L' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-M' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-N' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-O' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-P' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-S' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-T' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-U' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-V' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-W' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-X' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-Y' /tmp/pt_ar.log && grep -q '\[Playtest\] PASS arena AR-Z' /tmp/pt_ar.log && grep -q 'WAVE' /tmp/pt_ar.log && grep -q 'XP' /tmp/pt_ar.log && grep -q 'LEVEL' /tmp/pt_ar.log && grep -q 'CAMP' /tmp/pt_ar.log && grep -q 'JUNGLE' /tmp/pt_ar.log && grep -q 'REWARD' /tmp/pt_ar.log && grep -q 'MATCH' /tmp/pt_ar.log && grep -q 'QUEUE' /tmp/pt_ar.log && grep -q 'READY' /tmp/pt_ar.log && grep -q '\[Playtest\] river present on footprint' /tmp/pt_ar.log && grep -q '\[Playtest\] jump pads hop on footprint' /tmp/pt_ar.log; then
  AR_CODE=0
elif grep -q '\[Playtest\] FAIL arena AR-A' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-B' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-C' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-D' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-E' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-F' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-G' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-I' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-J' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-K' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-L' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-M' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-N' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-O' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-P' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-T' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-U' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-V' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-W' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-X' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-Y' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL arena AR-Z' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL river' /tmp/pt_ar.log || grep -q '\[Playtest\] FAIL jump pads' /tmp/pt_ar.log; then
  AR_CODE=1
elif [ "$AR_CODE" -eq 0 ]; then
  AR_CODE=1
fi
echo AR_CODE=$AR_CODE AR_ERR=$(grep -c 'SCRIPT ERROR' /tmp/pt_ar.log || true)
grep -E 'Playtest|SCRIPT ERROR|AR-A|AR-B|AR-C|AR-D|AR-E|AR-F|AR-G|AR-I|AR-J|AR-K|AR-L|AR-M|AR-N|AR-O|AR-P|AR-S|AR-T|AR-U|AR-V|AR-W|AR-X|AR-Y|AR-Z|WAVE|MINION|XP|LEVEL|CAMP|JUNGLE|REWARD|TITLE|MATCH|QUEUE|READY|river|jump pad|ClashJumpPads|prime|small camp|session shop|fifth kit|sixth kit|seventh kit|eighth kit|ninth kit' /tmp/pt_ar.log | head -80 || true
"$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/ui/MainMenu.tscn --quit-after 4 > /tmp/pt_mm.log 2>&1 || true
echo MM_ERR=$(grep -c 'SCRIPT ERROR' /tmp/pt_mm.log || true)
set +e
timeout 240 "$GODOT" --headless --path "$ROOT/godot" --scene res://scenes/world/OpenSpace.tscn -- --playtest-mechanics > /tmp/pt_mech.log 2>&1
MECH_CODE=$?
set -e
# Verdict is the [Playtest] line. Godot 4.7 dummy renderer may not exit after quit()
# (timeout 124) or the harness may OS.kill itself (137).
if grep -q '\[Playtest\] FAIL' /tmp/pt_mech.log; then
  MECH_CODE=1
elif grep -q '\[Playtest\] FL-N PASS' /tmp/pt_mech.log && grep -q 'FLEET MANIFEST 15/15' /tmp/pt_mech.log && grep -q '\[Playtest\] PASS AR-T' /tmp/pt_mech.log && grep -q '\[Playtest\] PASS AR-U' /tmp/pt_mech.log && grep -q '\[Playtest\] PASS AR-V' /tmp/pt_mech.log && grep -q '\[Playtest\] PASS AR-W' /tmp/pt_mech.log && grep -q '\[Playtest\] PASS AR-X' /tmp/pt_mech.log && grep -q '\[Playtest\] PASS AR-Y' /tmp/pt_mech.log && grep -q '\[Playtest\] PASS AR-Z' /tmp/pt_mech.log && grep -q 'WAVE' /tmp/pt_mech.log && grep -q 'XP' /tmp/pt_mech.log && grep -q 'CAMP' /tmp/pt_mech.log && grep -q 'JUNGLE' /tmp/pt_mech.log && grep -q 'REWARD' /tmp/pt_mech.log && grep -q 'MATCH' /tmp/pt_mech.log && grep -q 'QUEUE' /tmp/pt_mech.log && grep -q 'READY' /tmp/pt_mech.log; then
  MECH_CODE=0
else
  MECH_CODE=1
fi
echo MECH_CODE=$MECH_CODE MECH_ERR=$(grep -c 'SCRIPT ERROR' /tmp/pt_mech.log || true)
grep -E 'Playtest|SCRIPT ERROR|OS-H|ST-A|FL-N|FLEET MANIFEST 15/15|PASS AR-T|PASS AR-U|PASS AR-V|PASS AR-W|PASS AR-X|PASS AR-Y|PASS AR-Z|WAVE|MINION|XP|LEVEL|CAMP|JUNGLE|REWARD|TITLE|MATCH|QUEUE|READY|kits=' /tmp/pt_mech.log | tail -80 || true
grep -E 'SurfaceWater|CaveInterior|SurfaceFauna|SCRIPT ERROR|CanonPlates|PadAmbientLife|site_pin' /tmp/pt_os.log | head -20 || true
grep -E 'SCRIPT ERROR|CanonPlates|TestArena|AbilitySystem' /tmp/pt_ta.log | head -20 || true
grep -E 'SCRIPT ERROR|CanonPlates' /tmp/pt_mm.log | head -20 || true
