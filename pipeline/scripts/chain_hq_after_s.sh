#!/bin/bash
set -uo pipefail
cd "$(dirname "$0")/../.."
exec >>logs/hq_chain.log 2>&1
echo "chain wait start $(date -u) (5k 2-week policy)"
SPID=$(cat logs/hq_wave_s.pid 2>/dev/null || true)
if [ -n "$SPID" ]; then
  while kill -0 "$SPID" 2>/dev/null; do sleep 30; done
fi
echo "S finished $(date -u)"
set -a; source .env; set +a
# Point A brief temporarily to 2w subset
cp pipeline/briefs/hq_wave_a.json pipeline/briefs/hq_wave_a_full_backup.json 2>/dev/null || true
cp pipeline/briefs/hq_wave_a_2w.json pipeline/briefs/hq_wave_a.json
echo "using A 2w subset"
bash pipeline/scripts/run_hq_wave.sh A 200
# restore full A list for later
if [ -f pipeline/briefs/hq_wave_a_full_backup.json ]; then
  mv pipeline/briefs/hq_wave_a_full_backup.json pipeline/briefs/hq_wave_a.json
fi
echo "chain end $(date -u)"
