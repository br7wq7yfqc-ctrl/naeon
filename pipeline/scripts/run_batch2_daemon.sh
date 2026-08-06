#!/bin/bash
set -uo pipefail
cd "$(dirname "$0")/../.."
export PATH="$HOME/bin:/usr/local/bin:/Applications/Blender.app/Contents/MacOS:$PATH"
export PYTHONUNBUFFERED=1 BLENDER_BIN=/Applications/Blender.app/Contents/MacOS/Blender
set -a; source .env; set +a
mkdir -p logs
exec >>logs/batch2_daemon.log 2>&1
echo "==== BATCH2 START $(date -u) ===="
python3 -u - << 'PY'
import json, os, sys, time, subprocess, shutil
from pathlib import Path
ROOT = Path.cwd()
items = json.loads((ROOT/"pipeline/briefs/vertical_slice_batch2.json").read_text())
MIN = 150

def bal():
    import urllib.request, json as J
    key=os.environ["TRIPO_API_KEY"]
    base=os.environ.get("TRIPO_API_BASE","https://api.tripo3d.ai/v2/openapi").rstrip("/")
    req=urllib.request.Request(base+"/user/balance",headers={"Authorization":f"Bearer {key}"})
    with urllib.request.urlopen(req,timeout=30) as r:
        return float((J.loads(r.read().decode()).get("data") or {}).get("balance") or 0)

def has_asset(cat, name):
    return (ROOT/"assets"/cat/name/"manifest.json").exists()

done=[]; failed=[]
for item in items:
    name=item["name"]; cat=item.get("category","props")
    if has_asset(cat, name):
        print("SKIP", name, flush=True); done.append(name); continue
    glb=ROOT/"pipeline/inbox"/name/"model.glb"
    b=bal()
    print(f"\n=== {name} bal={b} ===", flush=True)
    if b < MIN:
        print("STOP reserve", MIN, flush=True); break
    env=os.environ.copy(); env["PYTHONUNBUFFERED"]="1"
    if not glb.exists():
        r=subprocess.run([sys.executable,"-u",str(ROOT/"pipeline/scripts/generate_tripo.py"),
            "--prompt",item["prompt"],"--name",name,"--priority",item.get("priority","B")],
            cwd=str(ROOT), env=env)
        if r.returncode!=0 or not glb.exists():
            print("GEN FAIL", name, flush=True); failed.append(name); continue
    else:
        print("REUSE inbox", flush=True)
    r=subprocess.run([sys.executable,"-u",str(ROOT/"pipeline/scripts/process_asset.py"),
        "--input",str(glb),"--name",name,"--category",cat], cwd=str(ROOT), env=env)
    if not has_asset(cat, name):
        if (ROOT/"assets/props"/name/"manifest.json").exists():
            (ROOT/"assets"/cat).mkdir(parents=True, exist_ok=True)
            shutil.move(str(ROOT/"assets/props"/name), str(ROOT/"assets"/cat/name))
        else:
            print("PROC FAIL", name, flush=True); failed.append(name); continue
    subprocess.run(["rclone","copy",str(ROOT/"assets"/cat/name),f"neon:neon/dev/{cat}/{name}"], cwd=str(ROOT))
    done.append(name)
    print(f"OK {name} bal={bal()}", flush=True)
summary={"done":done,"failed":failed,"balance":bal()}
print("SUMMARY", json.dumps(summary), flush=True)
(ROOT/"logs"/"batch2_summary.json").write_text(json.dumps(summary, indent=2))
PY
echo "==== BATCH2 END $(date -u) ===="
