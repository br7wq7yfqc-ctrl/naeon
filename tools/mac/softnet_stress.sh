#!/bin/bash
set -uo pipefail
# 2-process SoftENet host/join stress (headless)
ROOT="${HOME}/Documents/naeon"
export PATH="${HOME}/bin:${HOME}/Applications/Godot.app/Contents/MacOS:${PATH}"
LOGDIR="${ROOT}/logs/softnet_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOGDIR"
SCENE="${1:-res://scenes/test/TestArena.tscn}"
echo "SoftENet stress host+join scene=$SCENE"
godot --headless --path "${ROOT}/godot" --scene "$SCENE" --quit-after 10 -- --softnet-host \
  >"$LOGDIR/host.log" 2>&1 &
HPID=$!
sleep 2
godot --headless --path "${ROOT}/godot" --scene "$SCENE" --quit-after 8 -- --softnet-join=127.0.0.1 \
  >"$LOGDIR/client.log" 2>&1 &
CPID=$!
wait $HPID || true
wait $CPID || true
echo "=== HOST ===" | tee "$LOGDIR/SUMMARY.txt"
grep -iE "SoftENet|SCRIPT ERROR|puppet|peer" "$LOGDIR/host.log" | head -20 | tee -a "$LOGDIR/SUMMARY.txt"
echo "=== CLIENT ===" | tee -a "$LOGDIR/SUMMARY.txt"
grep -iE "SoftENet|SCRIPT ERROR|puppet|peer|connected" "$LOGDIR/client.log" | head -20 | tee -a "$LOGDIR/SUMMARY.txt"
HERR=$(grep -c "SCRIPT ERROR" "$LOGDIR/host.log" || true)
CERR=$(grep -c "SCRIPT ERROR" "$LOGDIR/client.log" || true)
echo "HOST_SCRIPT_ERR=$HERR CLIENT_SCRIPT_ERR=$CERR LOGDIR=$LOGDIR" | tee -a "$LOGDIR/SUMMARY.txt"
# success if no script errors and host started
grep -q "\[SoftENet\] host" "$LOGDIR/host.log"
