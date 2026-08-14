#!/usr/bin/env python3
"""Image-to-model for unbound/missing NAEON catalog positions."""
from __future__ import annotations
import json, os, sys, time
from pathlib import Path

ROOT = Path("/Users/vladmann/Documents/naeon")
POS = ROOT / "generations" / "asset_positions.json"
BIND = Path("/tmp/naeon_bind/bindings.json")
OCR = Path("/tmp/naeon_bind/ocr.jsonl")
INBOX = ROOT / "pipeline" / "inbox"
ASSETS = ROOT / "assets"
LOG = ROOT / "logs" / "tripo_image2model.jsonl"
MIN_BALANCE = 200
QUALITY_COST = 20

def load_env():
    envp = ROOT / ".env"
    if not envp.exists():
        return
    for line in envp.read_text().splitlines():
        line=line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k,v=line.split("=",1)
        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

def log(obj):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a") as f:
        f.write(json.dumps(obj, ensure_ascii=False)+"\n")
    print(json.dumps(obj, ensure_ascii=False), flush=True)

def session():
    import requests
    s = requests.Session()
    s.headers["Authorization"] = "Bearer " + os.environ["TRIPO_API_KEY"]
    return s

def base():
    return os.environ.get("TRIPO_API_BASE", "https://api.tripo3d.ai/v2/openapi").rstrip("/")

def balance(s):
    r = s.get(base()+"/user/balance", timeout=30)
    r.raise_for_status()
    return float((r.json().get("data") or {}).get("balance") or 0)

def already_has(name: str) -> bool:
    if (INBOX / name / "model.glb").exists():
        return True
    if list((INBOX / name).glob("*.glb")):
        return True
    if list(ASSETS.glob(f"**/{name}/manifest.json")):
        return True
    return False

def best_image(ids, ocr_by_id):
    cands=[]
    for i in ids:
        row=ocr_by_id.get(i)
        if not row:
            continue
        p=Path(row["path"])
        if not p.exists():
            continue
        score = 2 if row.get("folder")=="rendered" else 1
        score += min(p.stat().st_size/1e6, 3)
        cands.append((score, p))
    if not cands:
        return None
    cands.sort(reverse=True)
    return cands[0][1]

def upload(s, path: Path) -> str:
    ext = path.suffix.lower().lstrip(".") or "jpg"
    if ext=="jpeg":
        ext="jpg"
    with path.open("rb") as f:
        r = s.post(base()+"/upload", files={"file": (path.name, f, f"image/{ext}")}, timeout=120)
    if r.status_code >= 400:
        raise RuntimeError(f"upload {r.status_code} {r.text[:400]}")
    data=r.json()
    d = data.get("data") or data
    token = d.get("file_token") or d.get("image_token") or data.get("file_token") or data.get("image_token")
    if not token:
        raise RuntimeError(f"no upload token {data}")
    return token

def create_task(s, token: str, ext: str) -> str:
    payload={
        "type": "image_to_model",
        "model_version": os.environ.get("TRIPO_MODEL_VERSION", "v2.5-20250123"),
        "file": {"type": ext, "file_token": token, "image_token": token},
        "texture": True,
        "pbr": True,
        "texture_quality": "standard",
    }
    r=s.post(base()+"/task", json=payload, timeout=90)
    if r.status_code >= 400:
        raise RuntimeError(f"task {r.status_code} {r.text[:500]}")
    data=r.json()
    tid=(data.get("data") or {}).get("task_id") or data.get("task_id")
    if not tid:
        raise RuntimeError(f"no task_id {data}")
    return tid

def poll(s, tid: str, timeout=900):
    deadline=time.time()+timeout
    while time.time()<deadline:
        r=s.get(f"{base()}/task/{tid}", timeout=30)
        r.raise_for_status()
        payload=r.json().get("data") or r.json()
        st=str(payload.get("status","")).upper()
        if st in ("SUCCESS","SUCCEEDED","DONE","COMPLETED"):
            return payload
        if st in ("FAILED","ERROR","CANCELLED","BANNED"):
            raise RuntimeError(f"failed {payload}")
        time.sleep(5)
    raise TimeoutError(tid)

def download(task, dest: Path):
    urls=[]
    for key in ("model","pbr_model","base_model","model_url"):
        v=task.get(key)
        if isinstance(v,str) and v.startswith("http"):
            urls.append(v)
        if isinstance(v,dict) and v.get("url"):
            urls.append(v["url"])
    out=task.get("output") or task.get("result") or {}
    if isinstance(out, dict):
        for key in ("pbr_model","model","base_model","model_url"):
            v=out.get(key)
            if isinstance(v,str) and v.startswith("http"):
                urls.append(v)
            if isinstance(v,dict) and v.get("url"):
                urls.append(v["url"])
    if not urls:
        raise RuntimeError("no model url")
    url=urls[0]
    for u in urls:
        if "pbr" in u.lower():
            url=u
            break
    import requests
    dest.parent.mkdir(parents=True, exist_ok=True)
    with requests.get(url, stream=True, timeout=180) as r:
        r.raise_for_status()
        with dest.open("wb") as f:
            for chunk in r.iter_content(1024*256):
                if chunk:
                    f.write(chunk)
    return dest

def main():
    load_env()
    import requests
    qp=Path("/tmp/naeon_bind/tripo_queue.json")
    pos=json.loads(qp.read_text()) if qp.exists() else json.loads(POS.read_text())["items"]
    bind=json.loads(BIND.read_text())
    ocr_by={json.loads(l)["id"]: json.loads(l) for l in OCR.read_text().splitlines() if l.strip()}
    # ids per asset from bindings
    ids_by={}
    for rec in bind["bindings"]:
        if rec["status"]=="unrecognized":
            continue
        ids_by.setdefault(rec["asset"], []).append(rec["id"])
    s=session()
    bal=balance(s)
    log({"event":"start","balance":bal,"positions":len(pos)})
    done=failed=skipped=0
    for name, info in sorted(pos.items(), key=lambda kv: (-kv[1]["count"], kv[0])):
        if already_has(name):
            skipped += 1
            log({"event":"skip_exists","asset":name})
            continue
        img=best_image(ids_by.get(name, []), ocr_by)
        if img is None:
            failed += 1
            log({"event":"skip_no_image","asset":name})
            continue
        bal=balance(s)
        if bal < MIN_BALANCE + QUALITY_COST:
            log({"event":"stop_balance","balance":bal})
            break
        try:
            ext=img.suffix.lower().lstrip(".")
            if ext=="jpeg":
                ext="jpg"
            token=upload(s, img)
            tid=create_task(s, token, ext)
            log({"event":"created","asset":name,"task":tid,"image":str(img),"balance":bal})
            task=poll(s, tid)
            dest=INBOX/name/"model.glb"
            download(task, dest)
            meta={"name":name,"category":info.get("category"),"source_image":str(img),"task_id":tid,"consumed":task.get("consumed_credit"),"status":"success"}
            (INBOX/name/"meta.json").write_text(json.dumps(meta, indent=2))
            done += 1
            log({"event":"ok","asset":name,"bytes":dest.stat().st_size,"consumed":task.get("consumed_credit"),"balance":balance(s)})
        except Exception as e:
            failed += 1
            log({"event":"fail","asset":name,"error":str(e)[:400]})
    log({"event":"done","ok":done,"failed":failed,"skipped":skipped,"balance":balance(s)})
    return 0

if __name__=="__main__":
    raise SystemExit(main())
