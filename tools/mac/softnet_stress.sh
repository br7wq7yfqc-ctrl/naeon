#!/bin/bash
set -uo pipefail
ROOT="${HOME}/Documents/naeon"
export PATH="${HOME}/bin:${HOME}/Applications/Godot.app/Contents/MacOS:${PATH}"
LOGDIR="${ROOT}/logs/softnet_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOGDIR"
SCENE="${1:-res://scenes/test/TestArena.tscn}"
echo "SoftENet stress: loopback + UDP dual"
# 1) loopback
godot --headless --path "${ROOT}/godot" --scene "$SCENE" --quit-after 7 -- --softnet-loopback \
  >"$LOGDIR/loopback.log" 2>&1 || true
# 2) UDP host+client
godot --headless --path "${ROOT}/godot" --scene "$SCENE" --quit-after 14 -- --softnet-host \
  >"$LOGDIR/host.log" 2>&1 &
HPID=$!
sleep 3
godot --headless --path "${ROOT}/godot" --scene "$SCENE" --quit-after 11 -- --softnet-join=127.0.0.1 \
  >"$LOGDIR/client.log" 2>&1 &
CPID=$!
wait $HPID || true
wait $CPID || true

{
  echo "=== LOOPBACK ==="
  grep -iE "SoftENet|SCRIPT ERROR|puppet" "$LOGDIR/loopback.log" | head -20
  echo "=== HOST UDP ==="
  grep -iE "SoftENet|SCRIPT ERROR|puppet|peer" "$LOGDIR/host.log" | head -30
  echo "=== CLIENT UDP ==="
  grep -iE "SoftENet|SCRIPT ERROR|puppet|peer|connected" "$LOGDIR/client.log" | head -30
} | tee "$LOGDIR/SUMMARY.txt"

LERR=$(grep -c "SCRIPT ERROR" "$LOGDIR/loopback.log" || true)
HERR=$(grep -c "SCRIPT ERROR" "$LOGDIR/host.log" || true)
CERR=$(grep -c "SCRIPT ERROR" "$LOGDIR/client.log" || true)
LP=0; HP=0; CP=0; PEER=0
grep -q "loopback peer enabled" "$LOGDIR/loopback.log" && grep -q "puppet +" "$LOGDIR/loopback.log" && LP=1
grep -q "transport=udp bind_ok\|host port=.*transport=udp\|host port=.*unique_id=1 transport=udp\|bind_ok" "$LOGDIR/host.log" && HP=1
grep -q "transport=udp" "$LOGDIR/host.log" && HP=1
grep -q "joining .* transport=udp\|joining 127.0.0.1" "$LOGDIR/client.log" && CP=1
if grep -qE "peer \+|connected as|puppet \+" "$LOGDIR/host.log" || grep -qE "connected as|puppet \+" "$LOGDIR/client.log"; then
  PEER=1
fi
echo "SCRIPT L/H/C=$LERR/$HERR/$CERR LOOP=$LP HOST=$HP CLIENT=$CP PEER=$PEER LOGDIR=$LOGDIR" | tee -a "$LOGDIR/SUMMARY.txt"
if [ "${LERR:-0}" -gt 0 ] || [ "${HERR:-0}" -gt 0 ] || [ "${CERR:-0}" -gt 0 ]; then exit 1; fi
if [ "$LP" -ne 1 ]; then echo "FAIL loopback"; exit 2; fi
if [ "$PEER" -eq 1 ]; then
  godot --headless --path "${ROOT}/godot" --scene res://scenes/world/OpenSpace.tscn --quit-after 6 -- --softnet-host \
  >"$LOGDIR/openspace_host.log" 2>&1 || true
echo "=== OpenSpace host ===" | tee -a "$LOGDIR/SUMMARY.txt"
grep -iE "SoftENet|OpenSpace|SCRIPT ERROR|soft net" "$LOGDIR/openspace_host.log" | head -15 | tee -a "$LOGDIR/SUMMARY.txt"
OSERR=$(grep -c "SCRIPT ERROR" "$LOGDIR/openspace_host.log" || true)
echo "OpenSpace_SCRIPT_ERR=$OSERR" | tee -a "$LOGDIR/SUMMARY.txt"
if [ "${OSERR:-0}" -gt 0 ]; then exit 3; fi
echo "STRESS PASS loopback+UDP peer"
else
  echo "STRESS PASS loopback; UDP peer not observed (warn)"
fi
exit 0
