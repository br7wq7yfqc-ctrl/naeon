#!/usr/bin/env python3
from __future__ import annotations
import json, re, unicodedata
from collections import Counter
from pathlib import Path

ROOT = Path("/Users/vladmann/Documents/naeon")
GEN_CAT = ROOT / "generations" / "catalog.json"
OCR = Path("/tmp/naeon_bind/ocr.jsonl")
OUT_MAP = Path("/tmp/naeon_bind/bindings.json")
ASSETS = ROOT / "assets"
BRIEFS = ROOT / "pipeline" / "briefs"

NOISE = re.compile(
    r"\b(4[- ]view|orthographic|technical sheet|design lock|approved|"
    r"cinematic|canonical|modular|configuration|asymmetric|elongated|"
    r"silhouette|sheet|view|front|side|back|rear|top)\b",
    re.I,
)
JUNK_TITLE = re.compile(
    r"^(front view|side view|back view|rear view|top view|3/?4|"
    r"orthographic|scale|class|units|looking|doc|rev|"
    r"specifications|armament|notes|key features|material|"
    r"[\d\.\s,cmxym]+)$",
    re.I,
)
STOP = {
    "the","a","an","and","of","for","to","with","4","view","orthographic",
    "sheet","technical","design","lock","approved","cinematic","canonical",
    "modular","configuration","asymmetric","elongated","silhouette",
    "naeon","class","role",
}

CLASS_RX = [
    (r"battleship", "battleship"),
    (r"battlecruiser", "battlecruiser"),
    (r"capital cruiser", "capital_cruiser"),
    (r"capital carrier", "capital_carrier"),
    (r"mothership", "mothership"),
    (r"flagship", "flagship"),
    (r"frigate", "frigate"),
    (r"corvette", "corvette"),
    (r"gunship", "gunship"),
    (r"freighter", "freighter"),
    (r"interceptor", "interceptor"),
    (r"fighter", "fighter"),
    (r"bomber", "bomber"),
    (r"stealth", "stealth_ship"),
    (r"sniper", "sniper_ship"),
    (r"hoverbike", "hoverbike"),
    (r"hover tank", "hover_tank"),
    (r"scout rover", "scout_rover"),
    (r"crawler", "crawler"),
    (r"walker|mech", "walker"),
    (r"apc|ifv", "apc"),
    (r"heavy armor", "heavy_armor"),
    (r"medium armor", "medium_armor"),
    (r"light armor", "light_armor"),
    (r"helmet", "helmet"),
    (r"claim beacon", "claim_beacon"),
    (r"landing pad|dock landing", "landing_pad"),
    (r"utility drone", "utility_drone"),
    (r"combat drone|swarm", "combat_drone"),
    (r"logistic drone", "logistic_drone"),
    (r"heavy drone", "heavy_drone"),
    (r"medium drone", "medium_drone"),
    (r"light drone", "light_drone"),
    (r"support ship", "support_ship"),
    (r"debris|salvage|wreck", "debris_cluster"),
    (r"moba arena|hexagonal moba", "moba_arena"),
    (r"wake drill", "wake_drill"),
    (r"carbine|sidearm|to-t", "weapon_carbine"),
    (r"spore", "spore_prop"),
]

def slugify(s: str) -> str:
    s = unicodedata.normalize("NFKD", s)
    s = s.replace("—"," ").replace("–"," ").replace("//"," ")
    s = re.sub(r"[\"'`‘’“”]", "", s)
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    return re.sub(r"_+", "_", s).strip("_")[:72]

def title_from_text(text: str) -> str:
    if not text:
        return ""
    for raw in text.splitlines():
        line = re.sub(r"^[@•\-\s]+", "", raw.strip())
        line = re.sub(r"\s+", " ", line)
        if len(line) < 8:
            continue
        if JUNK_TITLE.search(line):
            continue
        if len(re.sub(r"[^a-zA-Z]", "", line)) < 4:
            continue
        return line
    return ""

def faction(title: str) -> str:
    t = title.lower()
    if "grot" in t or "grot" in t.replace("grdt","grot"):
        return "grot"
    if "cybernex" in t or "cnx" in t or "cnh" in t:
        return "cybernex"
    return ""

def klass(title: str) -> str:
    t = title.lower()
    for rx, name in CLASS_RX:
        if re.search(rx, t):
            return name
    return ""

def designation(title: str) -> str:
    m = re.search(r"\b(CNX[-\s]?\d+[A-Z]?|CNH[-\s]?\d+|CN[-\s]?\d+|UX[-\s]?\d+|TO[-\s]?T?\d+)\b", title, re.I)
    if m:
        return re.sub(r"[\s]+","-", m.group(1).upper())
    m = re.search(r"['\"]([A-Z][A-Z0-9 '\-]{2,})['\"]", title)
    if m:
        return slugify(m.group(1))
    return ""

def position_slug(title: str) -> str:
    fac = faction(title)
    k = klass(title)
    des = designation(title)
    parts = [p for p in (fac, k, des) if p]
    if len(parts) >= 2:
        return "_".join(parts)
    if k and fac:
        return f"{fac}_{k}"
    if k:
        return k
    # fallback: cleaned title minus noise words
    cleaned = NOISE.sub(" ", title)
    cleaned = re.sub(r"\b(cybernex|grot|grot)\b", "", cleaned, flags=re.I)
    sl = slugify(cleaned)
    tokens = [t for t in sl.split("_") if t and t not in STOP and len(t) > 1]
    if fac:
        tokens = [fac] + tokens
    if not tokens:
        return ""
    return "_".join(tokens[:6])

def category_for(title: str, slug: str) -> str:
    blob = f"{title} {slug}".lower()
    if any(w in blob for w in ("armor","helmet","suit","player")):
        return "characters"
    if any(w in blob for w in ("drone","walker","mech","rover","tank","hoverbike","crawler","apc")):
        return "vehicles"
    if any(w in blob for w in ("ship","hull","frigate","cruiser","carrier","battleship","fighter","bomber","corvette","gunship","mothership","flagship","interceptor","freighter")):
        return "ships"
    if any(w in blob for w in ("pad","arena","gate","wreck","debris")):
        return "environments"
    if any(w in blob for w in ("colony","habitat","solar","extractor","station")):
        return "colony"
    return "props"

def load_known() -> dict[str, str]:
    known = {}
    if ASSETS.is_dir():
        for man in ASSETS.rglob("manifest.json"):
            try:
                d = json.loads(man.read_text())
            except Exception:
                continue
            known[d.get("name") or man.parent.name] = d.get("category") or man.parent.parent.name
    for p in BRIEFS.glob("*.json"):
        try:
            d = json.loads(p.read_text())
        except Exception:
            continue
        if isinstance(d, list):
            for item in d:
                if isinstance(item, dict) and item.get("name"):
                    known.setdefault(item["name"], item.get("category") or "props")
    return known

def exact_or_none(slug: str, known: dict[str, str]) -> str | None:
    if slug in known:
        return slug
    # only exact-ish: slug startswith known or known startswith slug, min 12 chars
    for name in known:
        if len(name) >= 12 and (slug.startswith(name) or name.startswith(slug)):
            return name
    return None

def main() -> int:
    known = load_known()
    catalog = json.loads(GEN_CAT.read_text())
    by_id = {e["id"]: e for e in catalog["entries"]}
    ocr_rows = [json.loads(l) for l in OCR.read_text().splitlines() if l.strip()]
    bindings = []
    for row in ocr_rows:
        gid = row["id"]
        title = title_from_text(row.get("text") or "")
        if re.fullmatch(r"(cybernex|grot|grdt|cybernex\.)", title or "", re.I):
            title = ""
        slug = position_slug(title) if title else ""
        match = exact_or_none(slug, known) if slug else None
        if match:
            asset, cat, status = match, known[match], "matched"
        elif slug:
            asset, cat, status = slug, category_for(title, slug), "new_position"
            known.setdefault(slug, cat)
        else:
            asset, cat, status = f"unrecognized_{gid}", "unrecognized", "unrecognized"
        rec = {"id": gid, "folder": row.get("folder"), "title": title, "asset": asset, "category": cat, "status": status}
        bindings.append(rec)
        if gid in by_id:
            by_id[gid].update(title=title, asset=asset, category=cat, bind_status=status)
    catalog["bound"] = sum(1 for b in bindings if b["status"] != "unrecognized")
    catalog["unrecognized"] = sum(1 for b in bindings if b["status"] == "unrecognized")
    GEN_CAT.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
    positions = {}
    for b in bindings:
        if b["status"] == "unrecognized":
            continue
        positions.setdefault(b["asset"], {"category": b["category"], "ids": [], "titles": set()})
        positions[b["asset"]]["ids"].append(b["id"])
        if b["title"]:
            positions[b["asset"]]["titles"].add(b["title"])
    serial = {k: {"category": v["category"], "count": len(v["ids"]), "titles": sorted(v["titles"])} for k,v in positions.items()}
    OUT_MAP.write_text(json.dumps({
        "count": len(bindings),
        "status": dict(Counter(b["status"] for b in bindings)),
        "categories": dict(Counter(b["category"] for b in bindings)),
        "positions": len(serial),
        "position_index": serial,
        "bindings": bindings,
    }, indent=2, ensure_ascii=False) + "\n")
    print("status", dict(Counter(b["status"] for b in bindings)))
    print("positions", len(serial))
    print("categories", dict(Counter(b["category"] for b in bindings)))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
