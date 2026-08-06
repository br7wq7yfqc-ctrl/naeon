#!/bin/bash
set -uo pipefail
ROOT="${HOME}/Documents/naeon"
export PATH="${HOME}/bin:${HOME}/Applications/Godot.app/Contents/MacOS:${PATH}"
LOGDIR="${ROOT}/logs/softnet_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOGDIR"
SCENE="${1:-res://scenes/test/TestArena.tscn}"
echo "SoftENet loopback puppet stress scene=$SCENE"
godot --headless --path "${ROOT}/godot" --scene "$SCENE" --quit-after 8 -- --softnet-loopback \
  >"$LOGDIR/loopback.log" 2>&1 || true
echo "=== LOOPBACK ===" | tee "$LOGDIR/SUMMARY.txt"
grep -iE "SoftENet|SCRIPT ERROR|puppet" "$LOGDIR/loopback.log" | head -25 | tee -a "$LOGDIR/SUMMARY.txt"
ERR=$(grep -c "SCRIPT ERROR" "$LOGDIR/loopback.log" || true)
PUP=0
grep -q "\[SoftENet\] loopback peer enabled" "$LOGDIR/loopback.log" && grep -q "\[SoftENet\] puppet +" "$LOGDIR/loopback.log" && PUP=1
echo "SCRIPT_ERR=$ERR PUPPET_OK=$PUP LOGDIR=$LOGDIR" | tee -a "$LOGDIR/SUMMARY.txt"
if [ "${ERR:-0}" -gt 0 ]; then exit 1; fi
if [ "$PUP" -ne 1 ]; then
  echo "FAIL: loopback puppet not spawned" | tee -a "$LOGDIR/SUMMARY.txt"
  exit 2
fi
echo "STRESS PASS loopback puppet" | tee -a "$LOGDIR/SUMMARY.txt"
exit 0
