#!/usr/bin/env python3
"""Rebuild generations/catalog.json from local folder and upload to s3://neon/generations/."""
from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(os.environ.get("NAEON_ROOT", Path.home() / "Documents/naeon"))
GEN = Path(os.environ.get("NAEON_GENERATIONS", ROOT / "generations"))
OUT = GEN / "catalog.json"
BUCKET = os.environ.get("YC_STORAGE_BUCKET", "neon")
ENDPOINT = os.environ.get("YC_STORAGE_ENDPOINT", "https://storage.yandexcloud.net")
PROFILE = os.environ.get("AWS_PROFILE", "neon")

KIND_BY_FOLDER = {
    "rendered": "render",
    "imagine_images": "concept",
    "imagine_videos": "video",
}

SKIP_NAMES = {".DS_Store", "catalog.json"}


def kind_for(rel: Path) -> str:
    folder = rel.parts[0] if rel.parts else ""
    name = rel.name.lower()
    if "ortho" in name or "orthogonal" in name or name.startswith("ortho_"):
        return "ortho"
    return KIND_BY_FOLDER.get(folder, "concept")


def collect() -> list[dict]:
    entries: list[dict] = []
    if not GEN.is_dir():
        return entries
    for p in sorted(GEN.rglob("*")):
        if not p.is_file():
            continue
        if p.name in SKIP_NAMES or p.name.startswith("."):
            continue
        rel = p.relative_to(GEN)
        key = f"generations/{rel.as_posix()}"
        folder = rel.parts[0] if len(rel.parts) > 1 else ""
        entries.append(
            {
                "id": rel.stem,
                "key": key,
                "kind": kind_for(rel),
                "approved": True,
                "tripo_ready": kind_for(rel) in ("render", "ortho", "concept"),
                "folder": folder,
                "bytes": p.stat().st_size,
            }
        )
    return entries


def main() -> int:
    GEN.mkdir(parents=True, exist_ok=True)
    entries = collect()
    catalog = {
        "version": 1,
        "updated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "bucket": BUCKET,
        "prefix": "generations/",
        "purpose": "Approved design renders and orthogonal schemes for Tripo",
        "count": len(entries),
        "entries": entries,
    }
    OUT.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
    print(f"wrote {OUT} ({len(entries)} entries)")
    if "--no-upload" in sys.argv:
        return 0
    env = os.environ.copy()
    env["PATH"] = str(Path.home() / "Library/Python/3.9/bin") + ":" + env.get("PATH", "")
    cmd = [
        "aws",
        "s3",
        "cp",
        str(OUT),
        f"s3://{BUCKET}/generations/catalog.json",
        "--endpoint-url",
        ENDPOINT,
        "--profile",
        PROFILE,
        "--content-type",
        "application/json",
    ]
    print("→", " ".join(cmd))
    r = subprocess.run(cmd, env=env)
    return r.returncode


if __name__ == "__main__":
    raise SystemExit(main())
