#!/usr/bin/env python3
"""
Convenience wrapper: process_asset already emits dual faction LODs.
This script re-runs processing on all inbox models missing processed variants.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INBOX = ROOT / "inbox"
PROCESSED = ROOT / "processed"
PROCESS = Path(__file__).resolve().parent / "process_asset.py"


def main() -> int:
    if not INBOX.exists():
        print("No inbox/")
        return 0
    count = 0
    for glb in INBOX.glob("*/*.glb"):
        name = glb.parent.name
        out = PROCESSED / name
        if out.exists() and any(out.glob("*_cybernex_lod0.glb")):
            print(f"skip {name} (already processed)")
            continue
        print(f"→ process {name}")
        r = subprocess.run([sys.executable, str(PROCESS), "--input", str(glb), "--name", name])
        if r.returncode != 0:
            print(f"FAILED {name}")
            return r.returncode
        count += 1
    print(f"✓ processed {count} assets")
    return 0


if __name__ == "__main__":
    sys.exit(main())
