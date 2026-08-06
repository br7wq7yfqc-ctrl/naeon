#!/usr/bin/env python3
"""
NAEON — Tripo text-to-3D (OpenAPI v2) with HQ quality tiers.

Quality profiles:
  draft   — cheap blockout (texture off) ~10 cr
  standard — textured PBR default ~20 cr
  high    — detailed texture + higher faces ~40-60 cr
  ultra   — v3.1 + detailed texture + detailed geometry ~70-100 cr

Usage:
  python generate_tripo.py --prompt "..." --name x --quality high --priority A
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
DEFAULT_MODEL = os.getenv("TRIPO_MODEL_VERSION", "v2.5-20250123")
HQ_MODEL = os.getenv("TRIPO_HQ_MODEL_VERSION", "v3.1-20260211")

# Soft cost estimates (for budget planning; actual = task.consumed_credit)
COST_EST = {
    "draft": 10,
    "standard": 20,
    "high": 50,
    "ultra": 90,
}

QUALITY_PRESETS = {
    "draft": {
        "model_version": DEFAULT_MODEL,
        "texture": False,
        "pbr": False,
        "texture_quality": None,
        "geometry_quality": None,
        "face_limit_default": 5000,
    },
    "standard": {
        "model_version": DEFAULT_MODEL,
        "texture": True,
        "pbr": True,
        "texture_quality": "standard",
        "geometry_quality": None,
        "face_limit_default": 12000,
    },
    "high": {
        "model_version": DEFAULT_MODEL,
        "texture": True,
        "pbr": True,
        "texture_quality": "detailed",
        "geometry_quality": None,
        "face_limit_default": 20000,
    },
    "ultra": {
        "model_version": HQ_MODEL,
        "texture": True,
        "pbr": True,
        "texture_quality": "detailed",
        "geometry_quality": "detailed",
        "face_limit_default": 40000,
    },
}


def load_dotenv() -> None:
    for candidate in [
        Path.cwd() / ".env",
        Path(__file__).resolve().parents[2] / ".env",
        Path.home() / "Documents" / "naeon" / ".env",
        Path.home() / "naeon" / ".env",
    ]:
        if not candidate.is_file():
            continue
        for line in candidate.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
        break


def headers() -> dict:
    return {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}


def get_balance() -> dict | None:
    try:
        r = requests.get(f"{BASE_URL}/user/balance", headers=headers(), timeout=30)
        r.raise_for_status()
        data = r.json()
        return data.get("data", data)
    except Exception as e:
        print(f"[Tripo] balance check failed: {e}")
        return None


def create_text_task(
    prompt: str,
    *,
    model_version: str,
    texture: bool,
    pbr: bool,
    texture_quality: str | None,
    geometry_quality: str | None,
    face_limit: int | None,
    negative_prompt: str | None = None,
) -> str:
    payload: dict = {
        "type": "text_to_model",
        "prompt": prompt,
        "model_version": model_version,
        "texture": texture,
        "pbr": pbr,
    }
    if texture_quality:
        payload["texture_quality"] = texture_quality
    if geometry_quality:
        payload["geometry_quality"] = geometry_quality
    if face_limit:
        payload["face_limit"] = face_limit
    if negative_prompt:
        payload["negative_prompt"] = negative_prompt
    r = requests.post(f"{BASE_URL}/task", headers=headers(), json=payload, timeout=90)
    if r.status_code >= 400:
        print("[Tripo] create failed:", r.status_code, r.text[:800])
        # Fallback: strip advanced fields if API rejects
        if r.status_code in (400, 422) and ("texture_quality" in payload or "geometry_quality" in payload):
            print("[Tripo] retry without geometry_quality / with simpler payload…")
            payload.pop("geometry_quality", None)
            r = requests.post(f"{BASE_URL}/task", headers=headers(), json=payload, timeout=90)
            if r.status_code >= 400:
                # second fallback: standard texture only
                payload.pop("texture_quality", None)
                payload["texture"] = True
                payload["pbr"] = True
                print("[Tripo] retry standard texture…")
                r = requests.post(f"{BASE_URL}/task", headers=headers(), json=payload, timeout=90)
        if r.status_code >= 400:
            print("[Tripo] create failed final:", r.status_code, r.text[:800])
            r.raise_for_status()
    data = r.json()
    task_id = None
    if isinstance(data, dict):
        task_id = data.get("data", {}).get("task_id") if isinstance(data.get("data"), dict) else None
        task_id = task_id or data.get("task_id")
    if not task_id or not isinstance(task_id, str):
        raise RuntimeError(f"Unexpected create response: {data}")
    return task_id


def poll_task(task_id: str, timeout_s: int = 900, interval: float = 5.0) -> dict:
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
    urls: list[str] = []
    for key in ("model", "pbr_model", "base_model", "model_url"):
        v = task.get(key)
        if isinstance(v, str) and v.startswith("http"):
            urls.append(v)
        if isinstance(v, dict) and v.get("url"):
            urls.append(v["url"])
    output = task.get("output") or task.get("result") or {}
    if isinstance(output, dict):
        for key in ("model", "pbr_model", "base_model", "model_url", "rendered_image"):
            v = output.get(key)
            if isinstance(v, str) and v.startswith("http") and key != "rendered_image":
                urls.append(v)
            if isinstance(v, dict) and v.get("url"):
                urls.append(v["url"])
    if not urls:
        print("[Tripo] No download URL; dump:")
        print(json.dumps(task, indent=2)[:2000])
        return None
    # Prefer pbr_model if listed first in scan — urls order may have model first
    url = urls[0]
    for u in urls:
        if "pbr" in u.lower():
            url = u
            break
    dest = out_dir / "model.glb"
    print(f"  downloading {url[:90]}…")
    with requests.get(url, stream=True, timeout=180) as r:
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

    parser = argparse.ArgumentParser(description="Generate 3D asset via Tripo (HQ-capable)")
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--priority", choices=["A", "B", "C", "S"], default="B")
    parser.add_argument("--quality", choices=list(QUALITY_PRESETS.keys()), default=None,
                        help="draft|standard|high|ultra (overrides priority defaults)")
    parser.add_argument("--model-version", default=None)
    parser.add_argument("--face-limit", type=int, default=None)
    parser.add_argument("--texture-quality", choices=["standard", "detailed", "extreme"], default=None)
    parser.add_argument("--negative-prompt", default="blurry, low poly blob, text, watermark, base, plate")
    parser.add_argument("--min-balance", type=float, default=200.0, help="Refuse if balance below this after estimate")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-balance-guard", action="store_true")
    args = parser.parse_args()

    # Resolve quality from priority if not set
    quality = args.quality
    if quality is None:
        quality = {"S": "ultra", "A": "high", "B": "standard", "C": "draft"}.get(args.priority, "standard")
    preset = QUALITY_PRESETS[quality].copy()
    if args.model_version:
        preset["model_version"] = args.model_version
    if args.texture_quality:
        preset["texture_quality"] = args.texture_quality
    face_limit = args.face_limit if args.face_limit is not None else preset["face_limit_default"]
    est = COST_EST.get(quality, 50)

    if not API_KEY and not args.dry_run:
        print("ERROR: TRIPO_API_KEY not set")
        return 1

    INBOX.mkdir(parents=True, exist_ok=True)
    out_dir = INBOX / args.name
    out_dir.mkdir(exist_ok=True)

    print(f"[Tripo] priority={args.priority} quality={quality} est≈{est}cr | {args.name}")
    print(f"  model={preset['model_version']} texture={preset['texture']} pbr={preset['pbr']} "
          f"tq={preset['texture_quality']} gq={preset['geometry_quality']} faces={face_limit}")
    print(f"Prompt: {args.prompt}")

    bal = get_balance() if API_KEY else None
    credits = 0.0
    if bal is not None:
        print(f"Balance: {bal}")
        credits = float(bal.get("balance", 0) or 0)
        if credits < args.min_balance and not args.skip_balance_guard and not args.dry_run:
            print(f"ERROR: balance {credits} < min_balance {args.min_balance}")
            return 2
        if credits < est and not args.skip_balance_guard and not args.dry_run:
            print(f"ERROR: balance {credits} < estimated cost {est}")
            return 2

    if args.dry_run:
        meta = {
            "name": args.name, "prompt": args.prompt, "priority": args.priority,
            "quality": quality, "preset": preset, "est_cost": est, "status": "dry_run",
            "created": time.time(),
        }
        (out_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
        print(f"✓ Dry-run → {out_dir}/meta.json")
        return 0

    print("→ Creating task…")
    task_id = create_text_task(
        args.prompt,
        model_version=preset["model_version"],
        texture=bool(preset["texture"]),
        pbr=bool(preset["pbr"]),
        texture_quality=preset.get("texture_quality"),
        geometry_quality=preset.get("geometry_quality"),
        face_limit=face_limit,
        negative_prompt=args.negative_prompt,
    )
    print(f"  task_id={task_id}")
    print("→ Polling…")
    task = poll_task(task_id)
    consumed = task.get("consumed_credit") or task.get("credit") or None
    model_path = download_model(task, out_dir)

    meta = {
        "name": args.name,
        "prompt": args.prompt,
        "priority": args.priority,
        "quality": quality,
        "preset": preset,
        "est_cost": est,
        "consumed_credit": consumed,
        "service": "tripo",
        "status": "success" if model_path else "success_no_file",
        "task_id": task_id,
        "model_path": str(model_path) if model_path else None,
        "created": time.time(),
    }
    (out_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    bal2 = get_balance()
    print(f"✓ Done → {out_dir} consumed={consumed} balance_now={bal2}")
    if model_path:
        print("  Next: python process_asset.py --input", model_path, "--name", args.name, "--keep-materials")
    return 0


if __name__ == "__main__":
    sys.exit(main())
