#!/usr/bin/env python3
"""Reprocess all inbox models with --keep-materials (0 Tripo credits)."""
from __future__ import annotations
import json, os, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INBOX = ROOT / "pipeline" / "inbox"
ASSETS = ROOT / "assets"
LOG = ROOT / "logs" / "reprocess_keep_pbr.log"
SUMMARY = ROOT / "logs" / "reprocess_keep_pbr_summary.json"

# category map from existing assets tree
def category_for(name: str) -> str:
    for m in ASSETS.rglob("manifest.json"):
        if m.parent.name == name:
            return m.parent.parent.name
    # heuristics
    if name.startswith("player_") or name in ("combat_drone", "grot_infector"):
        return "characters"
    if name.startswith("ship_") or name in ("cargo_pod", "shield_module"):
        return "ships"
    if name in ("colony_habitat", "extractor_unit", "resource_crystal", "solar_panel", "fuel_tank"):
        return "colony"
    if name in ("landing_pad", "gate_arch", "walkway_segment", "asteroid_ore"):
        return "environments"
    return "props"

def has_textures(glb: Path) -> bool:
    import struct, json as J
    data = glb.read_bytes()
    if data[:4] != b"glTF":
        return False
    off = 12
    while off + 8 <= len(data):
        clen = struct.unpack_from("<I", data, off)[0]
        ctype = data[off+4:off+8]
        chunk = data[off+8:off+8+clen]
        off += 8 + clen
        if ctype == b"JSON":
            j = J.loads(chunk.decode("utf-8"))
            return len(j.get("images") or []) > 0
    return False

def main() -> int:
    LOG.parent.mkdir(exist_ok=True)
    items = sorted(INBOX.glob("*/model.glb"))
    done, failed, skipped = [], [], []
    for glb in items:
        name = glb.parent.name
        if name == "mac_smoke":
            skipped.append(name)
            continue
        cat = category_for(name)
        # skip if latest lod0 already has textures
        existing = ASSETS / cat / name / f"{name}_cybernex_lod0.glb"
        if existing.exists() and has_textures(existing):
            print(f"SKIP textured {cat}/{name}", flush=True)
            skipped.append(name)
            continue
        print(f"\\n=== REPROCESS {cat}/{name} ===", flush=True)
        t0 = time.time()
        r = subprocess.run(
            [sys.executable, "-u", str(ROOT / "pipeline/scripts/process_asset.py"),
             "--input", str(glb), "--name", name, "--category", cat, "--keep-materials"],
            cwd=str(ROOT),
            env={**os.environ, "PYTHONUNBUFFERED": "1", "BLENDER_BIN": os.environ.get("BLENDER_BIN", "")},
        )
        out = ASSETS / cat / name / f"{name}_cybernex_lod0.glb"
        ok = r.returncode == 0 and out.exists() and has_textures(out)
        # also accept clean_lod naming if wear was used
        if not ok:
            alt = ASSETS / cat / name / f"{name}_cybernex_clean_lod0.glb"
            ok = alt.exists() and has_textures(alt)
        if ok:
            done.append(name)
            print(f"OK {name} {time.time()-t0:.1f}s textures=yes", flush=True)
            # upload
            subprocess.run(["rclone", "copy", str(ASSETS/cat/name), f"neon:neon/dev/{cat}/{name}"], cwd=str(ROOT))
        else:
            failed.append(name)
            print(f"FAIL {name} rc={r.returncode}", flush=True)
    summary = {"done": done, "failed": failed, "skipped": skipped, "ts": time.time()}
    SUMMARY.write_text(json.dumps(summary, indent=2))
    print("SUMMARY", json.dumps(summary), flush=True)
    return 0 if not failed else 1

if __name__ == "__main__":
    raise SystemExit(main())
