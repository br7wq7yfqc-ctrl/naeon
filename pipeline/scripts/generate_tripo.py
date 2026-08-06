#!/usr/bin/env python3
"""
NAEON - Tripo generation helper (minimal cost focused)

Usage:
  export TRIPO_API_KEY="tsk_..."
  python generate_tripo.py --prompt "futuristic cybernex canine robot, dark neon" --name canine_scout --priority B

The script is intentionally conservative with credits.
"""

import argparse
import os
import sys
import time
import json
from pathlib import Path

try:
    import requests
except ImportError:
    print("Please install requests: pip install requests")
    sys.exit(1)

API_KEY = os.getenv("TRIPO_API_KEY")
BASE_URL = "https://api.tripo3d.ai"  # placeholder - check current Tripo API docs
INBOX = Path(__file__).resolve().parents[1] / "inbox"

def main():
    parser = argparse.ArgumentParser(description="Generate 3D asset via Tripo (free-tier friendly)")
    parser.add_argument("--prompt", required=True, help="Text prompt")
    parser.add_argument("--name", required=True, help="Asset name (folder friendly)")
    parser.add_argument("--priority", choices=["A", "B", "C"], default="B")
    parser.add_argument("--image", help="Optional reference image path")
    args = parser.parse_args()

    if not API_KEY:
        print("ERROR: TRIPO_API_KEY environment variable is not set")
        print("export TRIPO_API_KEY=tsk_...")
        sys.exit(1)

    INBOX.mkdir(parents=True, exist_ok=True)
    out_dir = INBOX / args.name
    out_dir.mkdir(exist_ok=True)

    print(f"[Tripo] Priority {args.priority} | {args.name}")
    print(f"Prompt: {args.prompt}")

    # NOTE: The exact endpoint and payload must be updated according to
    # current Tripo API documentation. This is a safe skeleton.
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "prompt": args.prompt,
        # Add model version / quality settings that consume fewer credits when possible
    }

    print("→ Submitting task to Tripo (skeleton call)...")
    print("  (Update endpoint according to official Tripo API docs)")

    # Placeholder for actual API call
    # response = requests.post(f"{BASE_URL}/v2/inference", headers=headers, json=payload)
    # ...

    meta = {
        "name": args.name,
        "prompt": args.prompt,
        "priority": args.priority,
        "service": "tripo",
        "status": "skeleton_only",
        "created": time.time(),
    }
    with open(out_dir / "meta.json", "w") as f:
        json.dump(meta, f, indent=2)

    print(f"✓ Meta written to {out_dir}/meta.json")
    print("  Next: implement real Tripo API call + download logic")
    print("  Then run process_asset.py on the downloaded .glb")

if __name__ == "__main__":
    main()
