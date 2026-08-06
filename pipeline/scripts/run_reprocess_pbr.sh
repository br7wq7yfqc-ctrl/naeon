#!/bin/bash
set -uo pipefail
cd "$(dirname "$0")/../.."
export PATH="$HOME/bin:/usr/local/bin:/Applications/Blender.app/Contents/MacOS:$PATH"
export PYTHONUNBUFFERED=1 BLENDER_BIN=/Applications/Blender.app/Contents/MacOS/Blender
set -a; source .env; set +a
mkdir -p logs
exec >>logs/reprocess_keep_pbr.log 2>&1
echo "==== REPROCESS RESUME $(date -u) ===="
python3 -u - << "PY"
import json, os, sys, subprocess, struct
from pathlib import Path
ROOT = Path.cwd()
rem = ROOT/"pipeline/briefs/reprocess_keep_pbr_remaining.json"
items = json.loads((rem if rem.exists() else ROOT/"pipeline/briefs/reprocess_keep_pbr.json").read_text())
done, failed = [], []

def has_tex(dest, name):
    for glb in list(dest.glob(f"{name}_*_lod0.glb"))[:6]:
        data = glb.read_bytes()
        if data[:4] != b"glTF": continue
        off = 12
        while off+8 <= len(data):
            clen = int.from_bytes(data[off:off+4],"little")
            ctype = data[off+4:off+8]
            chunk = data[off+8:off+8+clen]
            off += 8+clen
            if ctype == b"JSON":
                return bool(json.loads(chunk.decode()).get("images"))
    return False

for i, item in enumerate(items):
    name, cat, inp = item["name"], item["category"], item["input"]
    if name == "mac_smoke":
        continue
    dest = ROOT/"assets"/cat/name
    if dest.exists() and has_tex(dest, name):
        man = dest/"manifest.json"
        if man.exists() and json.loads(man.read_text()).get("keep_materials"):
            print(f"SKIP {name} already textured", flush=True)
            done.append(name)
            continue
    print(f"\n=== [{i+1}/{len(items)}] {cat}/{name} ===", flush=True)
    if not Path(inp).exists():
        failed.append(name); print("missing", inp, flush=True); continue
    r = subprocess.run([sys.executable,"-u",str(ROOT/"pipeline/scripts/process_asset.py"),
        "--input",inp,"--name",name,"--category",cat,"--keep-materials"], cwd=str(ROOT))
    if not dest.exists():
        failed.append(name); continue
    tex = has_tex(dest, name)
    print(f"OK {name} textures={tex}", flush=True)
    subprocess.run(["rclone","copy",str(dest),f"neon:neon/dev/{cat}/{name}"], cwd=str(ROOT))
    done.append(name)
(ROOT/"logs"/"reprocess_keep_pbr_summary.json").write_text(json.dumps({"done":done,"failed":failed}, indent=2))
print("SUMMARY", done, failed, flush=True)
PY
echo "==== END $(date -u) ===="
