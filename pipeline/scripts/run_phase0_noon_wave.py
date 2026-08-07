#!/usr/bin/env python3
"""Phase0 noon wave: Tripo → process dual-theme LODs. Stop if balance < 800."""
from __future__ import annotations
import json, os, sys, time, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRIEFS = ROOT / "pipeline/briefs/phase0_noon_wave.json"
MIN_BALANCE = 800
LOG = ROOT / "logs" / f"phase0_noon_{int(time.time())}.log"
LOG.parent.mkdir(exist_ok=True)

def log(msg: str) -> None:
    line = f"[{time.strftime('%H:%M:%S')}] {msg}"
    print(line, flush=True)
    LOG.open("a").write(line + "\n")

def load_env():
    envp = ROOT / ".env"
    if envp.exists():
        for line in envp.read_text().splitlines():
            if "=" in line and not line.strip().startswith("#"):
                k,v=line.split("=",1)
                os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

def balance() -> float:
    import requests
    base = os.environ.get("TRIPO_API_BASE", "https://api.tripo3d.ai/v2/openapi").rstrip("/")
    r = requests.get(base + "/user/balance", headers={"Authorization": "Bearer " + os.environ["TRIPO_API_KEY"]}, timeout=30)
    return float((r.json().get("data") or {}).get("balance") or 0)

def main() -> int:
    load_env()
    items = json.loads(BRIEFS.read_text())
    done, failed = [], []
    for item in items:
        name = item["name"]
        cat = item.get("category", "props")
        asset_dir = ROOT / "assets" / cat / name
        if (asset_dir / "manifest.json").exists() or any(asset_dir.glob("*_lod0.glb")):
            log(f"SKIP existing {cat}/{name}")
            done.append(name)
            continue
        bal = balance()
        log(f"BALANCE={bal} next={name} q={item.get('quality','standard')}")
        if bal < MIN_BALANCE:
            log(f"STOP reserve floor {MIN_BALANCE}")
            break
        gen = [
            sys.executable, str(ROOT / "pipeline/scripts/generate_tripo.py"),
            "--prompt", item["prompt"],
            "--name", name,
            "--priority", item.get("priority", "B"),
            "--quality", item.get("quality", "standard"),
        ]
        log(" $ " + " ".join(gen[:6]) + " …")
        rc = subprocess.run(gen, cwd=str(ROOT)).returncode
        if rc != 0:
            log(f"FAIL gen {name} rc={rc}")
            failed.append(name)
            continue
        # find inbox glb
        inbox = ROOT / "pipeline" / "inbox" / name
        glbs = list(inbox.glob("*.glb")) if inbox.exists() else []
        if not glbs:
            # also search inbox/*name*
            glbs = list((ROOT / "pipeline" / "inbox").glob(f"**/{name}*.glb"))
            glbs += list((ROOT / "pipeline" / "inbox").glob(f"**/{name}/model.glb"))
        if not glbs:
            log(f"FAIL no glb for {name}")
            failed.append(name)
            continue
        glb = glbs[0]
        proc = [
            sys.executable, str(ROOT / "pipeline/scripts/process_asset.py"),
            "--input", str(glb),
            "--name", name,
            "--category", cat,
            "--keep-materials",
        ]
        # process_asset may use different flags - try
        rc = subprocess.run(proc, cwd=str(ROOT)).returncode
        if rc != 0:
            proc2 = [
                sys.executable, str(ROOT / "pipeline/scripts/process_asset.py"),
                "--input", str(glb),
                "--name", name,
            ]
            rc = subprocess.run(proc2, cwd=str(ROOT)).returncode
        if rc != 0:
            log(f"FAIL process {name}")
            failed.append(name)
            continue
        log(f"OK {name}")
        done.append(name)
        # soft pause between gens
        time.sleep(2)
    log(f"DONE ok={done} fail={failed} bal={balance()}")
    return 0 if not failed or done else 1

if __name__ == "__main__":
    raise SystemExit(main())
