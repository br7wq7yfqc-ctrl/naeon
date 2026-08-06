#!/bin/bash
set -uo pipefail
ROOT="${HOME}/Documents/naeon"
export PATH="${HOME}/bin:${HOME}/Applications/Godot.app/Contents/MacOS:${PATH}"
LOGDIR="${ROOT}/logs/playtest_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOGDIR"
SUMMARY="$LOGDIR/SUMMARY.txt"
echo "NAEON full playtest $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee "$SUMMARY"

pass=0; fail=0
run_scene() {
  local name="$1" scene="$2" sec="${3:-5}"
  local log="$LOGDIR/${name}.log"
  echo "=== $name ===" | tee -a "$SUMMARY"
  godot --headless --path "${ROOT}/godot" --scene "$scene" --quit-after "$sec" >"$log" 2>&1 || true
  local errs parse busy
  errs=$(grep -c "SCRIPT ERROR" "$log" 2>/dev/null || true); errs=${errs:-0}
  parse=$(grep -c "Parse Error" "$log" 2>/dev/null || true); parse=${parse:-0}
  busy=$(grep -c "Parent node is busy" "$log" 2>/dev/null || true); busy=${busy:-0}
  # Headless dummy renderer noise (not a game script failure):
  local mesh_null
  mesh_null=$(grep -c "Parameter \"m\" is null" "$log" 2>/dev/null || true); mesh_null=${mesh_null:-0}
  local status="PASS"
  if [ "${errs:-0}" -gt 0 ] || [ "${parse:-0}" -gt 0 ] || [ "${busy:-0}" -gt 0 ]; then
    status="FAIL"; fail=$((fail+1))
  else
    pass=$((pass+1))
  fi
  echo "  $status  SCRIPT_ERROR=$errs PARSE=$parse BUSY_ADD_CHILD=$busy HEADLESS_MESH_NULL=$mesh_null" | tee -a "$SUMMARY"
  grep -iE "\[Player\]|\[SoftNet|\[SoftENet|\[Clash|\[OpenSpace|\[Ship|form mesh|SCRIPT ERROR|Parent node" "$log" 2>/dev/null | head -12 | sed "s/^/    /" | tee -a "$SUMMARY"
  echo "" | tee -a "$SUMMARY"
}

run_scene "00_MainBoot" "res://scenes/world/OpenSpace.tscn" 5
run_scene "01_OpenSpace" "res://scenes/world/OpenSpace.tscn" 6
run_scene "02_TestArena" "res://scenes/test/TestArena.tscn" 6
run_scene "03_SpaceTest" "res://scenes/test/SpaceTest.tscn" 5
run_scene "04_Player" "res://scenes/player/Player.tscn" 3
run_scene "05_Ship" "res://scenes/ship/Ship.tscn" 3
run_scene "06_CombatDummy" "res://scenes/combat/CombatDummy.tscn" 2
run_scene "07_Turret" "res://scenes/combat/Turret.tscn" 2
run_scene "08_Extractor" "res://scenes/colony/Extractor.tscn" 2
run_scene "09_ResourceNode" "res://scenes/colony/ResourceNode.tscn" 2

echo "=== TOTAL PASS=$pass FAIL=$fail ===" | tee -a "$SUMMARY"
echo "LOGDIR=$LOGDIR" | tee -a "$SUMMARY"
# SoftENet host smoke (no scene)
echo "=== SoftENet host smoke ===" | tee -a "$SUMMARY"
godot --headless --path "${ROOT}/godot" --quit-after 2 2>&1 | tee "$LOGDIR/enet_boot.log" | tail -5 | tee -a "$SUMMARY"
[ "$fail" -eq 0 ]
