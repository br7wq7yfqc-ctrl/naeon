# NAEON — Unified Handoff (Build Sessions)

**Date:** 2026-08-06  
**Author:** Design Lead (Grok) + implementation snapshot  
**Skill:** `naeon-holistic-economical` v1.2  
**Repo:** https://github.com/br7wq7yfqc-ctrl/naeon

---

## 1. Snapshot

### Mode
Unified multi-track session is **active** (A Core + B Space + C Assets). Parallel sub-sessions may resume using the briefs in `docs/HANDOFFS.md`.

### Implementation (as of this handoff)
| Track | Status |
|-------|--------|
| **A** TPS + Ability + Ownership + TestArena | Playable vertical slice |
| **B** ShipController + modules + colony seed | SpaceTest + Extractor |
| **C** Asset pipeline Tripo→Blender→dual-theme | Scripts live; **Tripo balance = 0** blocks real generation |

### Infrastructure
- Godot **4.3** under `godot/`
- Main test scenes: `godot/scenes/test/TestArena.tscn`, `SpaceTest.tscn`
- Asset VM: `ubuntu@84.201.170.6` (Blender 4.2.9 + venv + rclone)
- Bucket: Yandex Object Storage **`neon`** (rclone remote still needs YC keys on machines)
- Mac: repo `~/Documents/naeon`, local `.env` only
- **Never commit secrets / `.env` / heavy `/assets/`**

### Design corpus (canonical)
Full map: `docs/rules/00`–`14`, `docs/legal/`, `docs/lore/`, `docs/SHARED_AGENT_MEMORY.md`.  
Skill mirror: `docs/HOLISTIC_DEV_SKILL.md`.

**Canonical paths (do not use redirects for edits):**
- UI → `docs/rules/10_UI_INTERFACE_LAYER.md`
- Economy → `docs/rules/05_ECONOMY_RBE_BIOMASS.md`
- Pillars → `docs/rules/00_DESIGN_PILLARS.md`

---

## 2. Non-negotiables (all sessions)

1. **No P2W** — sub/tokens = cosmetics, voice, narrative, generation quota only.
2. **Soft Knowledge only** — info/QoL, never raw damage/HP/CDR gates.
3. **Asymmetric Cybernex / gROT** — both viable; Hack vs Firewall counterplay.
4. **Dynamic Ownership** — visual + gameplay; Arena influence soft/capped.
5. **Readable UI** — threat states use shape + text, not colour alone.
6. **Economical assets** — Tripo-first, free-tier, one mesh → dual faction variants in Blender.
7. **Godot 4.x**, Mac + Windows, low-end first.

Load skill `naeon-holistic-economical` at session start.

---

## 3. How to resume

1. `git pull origin main`
2. Read this file + `docs/HANDOFFS.md` (session-specific) + `docs/SHARED_AGENT_MEMORY.md`
3. Read only the rules docs listed for your track
4. Work on a feature branch; small focused commits
5. Update `docs/SESSION_STATUS.md` when pausing
6. Append durable decisions to `docs/SHARED_AGENT_MEMORY.md`

---

## 4. Blockers (ops)

| Blocker | Action owner |
|---------|----------------|
| Tripo balance = 0 | Owner tops up credits |
| rclone `neon` keys | Configure YC S3 on Mac + VM |
| Optional SSH to `89.169.142.255` | Only if that host joins fleet |

Design does not unblock ops; code can continue with placeholders.

---

## 5. Design gaps still open (numeric / content)

Priority for Design Lead (not blockers for code placeholders):

1. Economy conversion ratios + crafting tier costs  
2. Ability rank 4–5 numbers  
3. Voice achievement thresholds  
4. MOBA exact daily War Score caps  
5. Campaign quest ID lists per act  

Code may use v0.1 bands from `04_ABILITY_PARAMETERS` and `05_ECONOMY_*` until updated.

---

*Next detail: per-session briefs in `docs/HANDOFFS.md`.*
