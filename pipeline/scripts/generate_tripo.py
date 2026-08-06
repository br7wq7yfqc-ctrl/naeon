#!/usr/bin/env python3
"""
NAEON — Tripo text-to-3D generation (official OpenAPI v2).

Usage:
  export TRIPO_API_KEY="tsk_..."
  python generate_tripo.py --prompt "futuristic cybernex canine robot, dark neon" --name canine_scout --priority B

API base: https://api.tripo3d.ai/v2/openapi
Never commit real keys — use env / .env only.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

try:
    import requests
except ImportError:
    print("Please install requests: pip install requests")
    sys.exit(1)

API_KEY = os.getenv("TRIPO_API_KEY", "")
BASE_URL = os.getenv("TRIPO_API_BASE", "https://api.tripo3d.ai/v2/openapi").rstrip("/")
INBOX = Path(__file__).resolve().parents[1] / "inbox"

# Prefer cheaper / free-tier friendly model versions first
DEFAULT_MODEL = os.getenv("TRIPO_MODEL_VERSION", "v2.5-20250123")


def load_dotenv() -> None:
    """Load nearest .env without requiring python-dotenv."""
    for candidate in [
        Path.cwd() / ".env",
        Path(__file__).resolve().parents[2] / ".env",
        Path.home() / "naeon" / ".env",
        Path.home() / "Documents" / "naeon" / ".env",
    ]:
        if not candidate.is_file():
            continue
        for line in candidate.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            k, v = k.strip(), v.strip().strip('"').strip("'")
            os.environ.setdefault(k, v)
        break


def headers() -> dict:
    return {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
    }


def get_balance() -> dict | None:
    try:
        r = requests.get(f"{BASE_URL}/user/balance", headers=headers(), timeout=30)
        r.raise_for_status()
        data = r.json()
        return data.get("data", data)
    except Exception as e:
        print(f"[Tripo] balance check failed: {e}")
        return None


def create_text_task(prompt: str, model_version: str, face_limit: int | None) -> str:
    payload: dict = {
        "type": "text_to_model",
        "prompt": prompt,
        "model_version": model_version,
    }
    if face_limit:
        payload["face_limit"] = face_limit
    # Prefer texture on for Priority A/B; skip for pure blockouts if desired
    payload["texture"] = True
    r = requests.post(f"{BASE_URL}/task", headers=headers(), json=payload, timeout=60)
    if r.status_code >= 400:
        print("[Tripo] create failed:", r.status_code, r.text[:500])
        r.raise_for_status()
    data = r.json()
    # Response shapes vary: {data:{task_id}} or {task_id}
    task_id = None
    if isinstance(data, dict):
        task_id = data.get("data", {}).get("task_id") if isinstance(data.get("data"), dict) else None
        task_id = task_id or data.get("task_id") or data.get("data")
    if not task_id or not isinstance(task_id, str):
        raise RuntimeError(f"Unexpected create response: {data}")
    return task_id


def poll_task(task_id: str, timeout_s: int = 600, interval: float = 4.0) -> dict:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        r = requests.get(f"{BASE_URL}/task/{task_id}", headers=headers(), timeout=30)
        r.raise_for_status()
        data = r.json()
        payload = data.get("data", data)
        status = str(payload.get("status", "")).upper()
        print(f"  status={status}")
        if status in ("SUCCESS", "SUCCEEDED", "DONE", "COMPLETED"):
            return payload
        if status in ("FAILED", "ERROR", "CANCELLED", "BANNED"):
            raise RuntimeError(f"Task failed: {payload}")
        time.sleep(interval)
    raise TimeoutError(f"Task {task_id} timed out after {timeout_s}s")


def download_model(task: dict, out_dir: Path) -> Path | None:
    # Common fields: model, output.model, result.pbr_model, files
    urls: list[str] = []
    for key in ("model", "pbr_model", "base_model", "model_url"):
        v = task.get(key)
        if isinstance(v, str) and v.startswith("http"):
            urls.append(v)
        if isinstance(v, dict) and v.get("url"):
            urls.append(v["url"])
    output = task.get("output") or task.get("result") or {}
    if isinstance(output, dict):
        for key in ("model", "pbr_model", "base_model", "model_url"):
            v = output.get(key)
            if isinstance(v, str) and v.startswith("http"):
                urls.append(v)
            if isinstance(v, dict) and v.get("url"):
                urls.append(v["url"])
    if not urls:
        print("[Tripo] No download URL in task payload; dumping meta only")
        print(json.dumps(task, indent=2)[:1500])
        return None
    url = urls[0]
    dest = out_dir / "model.glb"
    print(f"  downloading {url[:80]}…")
    with requests.get(url, stream=True, timeout=120) as r:
        r.raise_for_status()
        with open(dest, "wb") as f:
            for chunk in r.iter_content(1024 * 256):
                if chunk:
                    f.write(chunk)
    print(f"  saved {dest} ({dest.stat().st_size} bytes)")
    return dest


def main() -> int:
    load_dotenv()
    global API_KEY, BASE_URL
    API_KEY = os.getenv("TRIPO_API_KEY", "")
    BASE_URL = os.getenv("TRIPO_API_BASE", BASE_URL).rstrip("/")

    parser = argparse.ArgumentParser(description="Generate 3D asset via Tripo")
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--priority", choices=["A", "B", "C"], default="B")
    parser.add_argument("--model-version", default=DEFAULT_MODEL)
    parser.add_argument("--face-limit", type=int, default=None)
    parser.add_argument("--dry-run", action="store_true", help="Write meta only, no API spend")
    parser.add_argument("--skip-balance-guard", action="store_true")
    args = parser.parse_args()

    if not API_KEY and not args.dry_run:
        print("ERROR: TRIPO_API_KEY not set")
        return 1

    INBOX.mkdir(parents=True, exist_ok=True)
    out_dir = INBOX / args.name
    out_dir.mkdir(exist_ok=True)

    print(f"[Tripo] Priority {args.priority} | {args.name}")
    print(f"Prompt: {args.prompt}")
    print(f"API: {BASE_URL}")

    bal = get_balance() if API_KEY else None
    if bal is not None:
        print(f"Balance: {bal}")
        credits = float(bal.get("balance", 0) or 0)
        if credits <= 0 and not args.skip_balance_guard and not args.dry_run:
            print("ERROR: Tripo balance is 0. Refusing to spend. Top up credits or use --skip-balance-guard / --dry-run.")
            meta = {
                "name": args.name,
                "prompt": args.prompt,
                "priority": args.priority,
                "service": "tripo",
                "status": "blocked_zero_balance",
                "balance": bal,
                "created": time.time(),
            }
            (out_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
            return 2

    if args.dry_run:
        meta = {
            "name": args.name,
            "prompt": args.prompt,
            "priority": args.priority,
            "service": "tripo",
            "status": "dry_run",
            "created": time.time(),
        }
        (out_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
        print(f"✓ Dry-run meta → {out_dir}/meta.json")
        return 0

    face_limit = args.face_limit
    if face_limit is None and args.priority == "C":
        face_limit = 5000
    elif face_limit is None and args.priority == "B":
        face_limit = 10000

    print("→ Creating task…")
    task_id = create_text_task(args.prompt, args.model_version, face_limit)
    print(f"  task_id={task_id}")
    print("→ Polling…")
    task = poll_task(task_id)
    model_path = download_model(task, out_dir)

    meta = {
        "name": args.name,
        "prompt": args.prompt,
        "priority": args.priority,
        "service": "tripo",
        "status": "success" if model_path else "success_no_file",
        "task_id": task_id,
        "model_path": str(model_path) if model_path else None,
        "created": time.time(),
    }
    (out_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"✓ Done → {out_dir}")
    if model_path:
        print("  Next: python process_asset.py --input", model_path, "--name", args.name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
