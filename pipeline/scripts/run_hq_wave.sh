#!/bin/bash
# Usage: bash pipeline/scripts/run_hq_wave.sh S|A|C [min_balance]
set -uo pipefail
WAVE="${1:-S}"
MIN_BAL="${2:-200}"
cd "$(dirname "$0")/../.."
export PATH="$HOME/bin:/usr/local/bin:/Applications/Blender.app/Contents/MacOS:$PATH"
export PYTHONUNBUFFERED=1 BLENDER_BIN=/Applications/Blender.app/Contents/MacOS/Blender
set -a; source .env; set +a
WLOWER=$(echo "$WAVE" | tr "[:upper:]" "[:lower:]")
BRIEF="pipeline/briefs/hq_wave_${WLOWER}.json"
LOG="logs/hq_wave_${WAVE}.log"
mkdir -p logs
exec >>"$LOG" 2>&1
echo "==== HQ WAVE $WAVE START $(date -u) min_balance=$MIN_BAL ===="
python3 -u - << PY
import json, os, sys, subprocess, shutil
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path.cwd()
wave = "${WAVE}".upper()
brief = ROOT / f"pipeline/briefs/hq_wave_{wave.lower()}.json"
min_bal = float("${MIN_BAL}")
items = json.loads(brief.read_text())
policy_path = ROOT / "pipeline/briefs/hq_budget_policy.json"
policy = json.loads(policy_path.read_text()) if policy_path.exists() else {
    "cap_credits": 5000, "hard_reserve": 200, "usable_this_window": 4800
}
cap_usable = float(policy.get("usable_this_window", 4800))
reserve = float(policy.get("hard_reserve", 200))

def balance():
    import urllib.request, json as J
    key = os.environ["TRIPO_API_KEY"]
    base = os.environ.get("TRIPO_API_BASE", "https://api.tripo3d.ai/v2/openapi").rstrip("/")
    req = urllib.request.Request(base + "/user/balance", headers={"Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=30) as r:
        d = (J.loads(r.read().decode()).get("data") or {})
        return float(d.get("balance") or 0), float(d.get("frozen") or 0)

def hq_spent():
    total = 0.0
    for meta in (ROOT / "pipeline/inbox").glob("*/meta.json"):
        try:
            m = json.loads(meta.read_text())
        except Exception:
            continue
        if m.get("quality") in ("ultra", "high", "standard") and m.get("consumed_credit") is not None:
            total += float(m["consumed_credit"])
    return total

done, failed = [], []
for i, item in enumerate(items):
    name = item["name"]
    cat = item.get("category", "props")
    quality = item.get("quality", "high")
    priority = item.get("priority", "A")
    prompt = item["prompt"]
    b, fr = balance()
    spent = hq_spent()
    remain_cap = max(0.0, cap_usable - spent)
    print(f"\n=== [{i+1}/{len(items)}] {cat}/{name} q={quality} bal={b} frozen={fr} spent={spent:.0f}/{cap_usable:.0f} remain_cap={remain_cap:.0f} ===", flush=True)
    if b < min_bal:
        print(f"STOP balance floor {min_bal}", flush=True)
        break
    if remain_cap < 25:
        print(f"STOP 2-week cap exhausted (spent {spent} usable {cap_usable})", flush=True)
        break
    # est cost gate
    est = {"ultra": 50, "high": 40, "standard": 20, "draft": 10}.get(quality, 40)
    if est > remain_cap:
        print(f"STOP next est {est} > remain_cap {remain_cap}", flush=True)
        break
    if b - est < reserve and b < reserve + 30:
        print(f"STOP would breach hard reserve {reserve}", flush=True)
        break
    r = subprocess.run([
        sys.executable, "-u", str(ROOT / "pipeline/scripts/generate_tripo.py"),
        "--prompt", prompt,
        "--name", name,
        "--priority", priority if priority in ("A", "B", "C", "S") else "A",
        "--quality", quality,
        "--min-balance", str(min_bal),
    ], cwd=str(ROOT))
    glb = ROOT / "pipeline/inbox" / name / "model.glb"
    if r.returncode != 0 or not glb.exists():
        failed.append(name)
        print("GEN FAIL", name, flush=True)
        continue
    r2 = subprocess.run([
        sys.executable, "-u", str(ROOT / "pipeline/scripts/process_asset.py"),
        "--input", str(glb),
        "--name", name,
        "--category", cat,
        "--keep-materials",
    ], cwd=str(ROOT))
    dest = ROOT / "assets" / cat / name
    if not dest.exists():
        alt = ROOT / "assets/props" / name
        if alt.exists() and cat != "props":
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(alt), str(dest))
    if not dest.exists():
        failed.append(name)
        print("PROC FAIL", name, flush=True)
        continue
    subprocess.run(["rclone", "copy", str(dest), f"neon:neon/dev/{cat}/{name}"], cwd=str(ROOT))
    done.append(name)
    bb, _ = balance()
    print(f"OK {name} bal={bb} spent_now={hq_spent():.0f}", flush=True)

b, fr = balance()
summary = {
    "wave": wave,
    "done": done,
    "failed": failed,
    "balance": b,
    "frozen": fr,
    "hq_spent": hq_spent(),
    "cap_usable": cap_usable,
    "ended": datetime.now(timezone.utc).isoformat(),
}
(ROOT / f"logs/hq_wave_{wave}_summary.json").write_text(json.dumps(summary, indent=2))
print("SUMMARY", json.dumps(summary), flush=True)
PY
echo "==== HQ WAVE $WAVE END $(date -u) ===="
