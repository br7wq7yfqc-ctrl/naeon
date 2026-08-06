#!/usr/bin/env python3
"""Economical batch: Tripo generate → Blender process → rclone upload."""
from __future__ import annotations
import json, os, sys, time, subprocess, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRIEFS = ROOT / "pipeline/briefs/vertical_slice_batch.json"
MIN_BALANCE = 200  # keep reserve
LOG = ROOT / "logs" / f"batch_{int(time.time())}.log"
LOG.parent.mkdir(exist_ok=True)

def log(msg: str) -> None:
    line = f"[{time.strftime('%H:%M:%S')}] {msg}"
    print(line, flush=True)
    with LOG.open("a") as f:
        f.write(line + "\n")

def balance() -> float:
    key = os.environ["TRIPO_API_KEY"]
    base = os.environ.get("TRIPO_API_BASE", "https://api.tripo3d.ai/v2/openapi").rstrip("/")
    req = urllib.request.Request(base + "/user/balance", headers={"Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.loads(r.read().decode())
    return float((data.get("data") or {}).get("balance") or 0)

def run(cmd: list[str]) -> int:
    log(" $ " + " ".join(cmd))
    p = subprocess.run(cmd, cwd=str(ROOT))
    return p.returncode

def main() -> int:
    items = json.loads(BRIEFS.read_text())
    # skip already processed
    done = []
    failed = []
    for item in items:
        name = item["name"]
        cat = item.get("category", "props")
        asset_dir = ROOT / "assets" / cat / name
        if (asset_dir / "manifest.json").exists():
            log(f"SKIP existing {cat}/{name}")
            done.append(name)
            continue
        bal = balance()
        log(f"BALANCE={bal}  next={name}")
        if bal < MIN_BALANCE:
            log(f"STOP reserve floor {MIN_BALANCE}")
            break
        # generate
        gen = [
            sys.executable, str(ROOT / "pipeline/scripts/generate_tripo.py"),
            "--prompt", item["prompt"],
            "--name", name,
            "--priority", item.get("priority", "B"),
        ]
        rc = run(gen)
        if rc != 0:
            log(f"FAIL generate {name} rc={rc}")
            failed.append(name)
            continue
        glb = ROOT / "pipeline/inbox" / name / "model.glb"
        if not glb.exists():
            # find any glb
            cands = list((ROOT / "pipeline/inbox" / name).glob("*.glb"))
            if not cands:
                log(f"FAIL no glb for {name}")
                failed.append(name)
                continue
            glb = cands[0]
        # process
        proc = [
            sys.executable, str(ROOT / "pipeline/scripts/process_asset.py"),
            "--input", str(glb),
            "--name", name,
            "--category", cat,
        ]
        rc = run(proc)
        if rc != 0:
            log(f"FAIL process {name}")
            failed.append(name)
            continue
        # upload
        if (asset_dir).exists():
            run(["rclone", "copy", str(asset_dir), f"neon:neon/dev/{cat}/{name}"])
        done.append(name)
        log(f"OK {name}  balance_now={balance()}")
    log(f"DONE ok={done} failed={failed} final_balance={balance()}")
    summary = {"done": done, "failed": failed, "balance": balance()}
    (ROOT / "logs" / "batch_summary.json").write_text(json.dumps(summary, indent=2))
    return 0 if not failed or done else 1

if __name__ == "__main__":
    raise SystemExit(main())
