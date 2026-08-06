# NAEON — Handoff Documents for Parallel Build-Sessions

**Date:** 2026-08-05  
**Status:** Current multi-agent session stopped. Ready for parallel build-sessions.

---

## 1. Current Project State (Summary)

### Repository
- **Repo:** https://github.com/br7wq7yfqc-ctrl/naeon
- **Main branch:** up to date with CONCEPT.md v1.2, DEVELOPMENT_PLAN.md v2.0
- **Godot project:** `godot/` (early foundation)
- **Asset storage:** Yandex Object Storage bucket `neon`
- **CI/CD:** GitHub Actions (validate + headless + export jobs)

### What is already done
- Full game concept (lore, factions, systems, educational mechanics, Dynamic Ownership, etc.)
- Development plan by phases
- Godot project skeleton + Ability System + PlayerController + OwnershipData
- Hacking / Nex-Firewall foundation
- Contribution + KnowledgeRank data structures
- Asset pipeline design (Tripo-first, free-tier focused)
- rclone sync scripts + auto-sync documentation
- Basic CI (secret scan, Godot headless, export placeholders)

### What is NOT done yet
- Full playable TestArena / Ship test scenes
- Complete Blender processing pipeline on VM
- Working Tripo API integration (only skeleton)
- Multiplayer / netcode
- Visual Dynamic Ownership transformation
- Any real 3D assets beyond placeholders

---

## 2. Recommended Parallel Build-Sessions

### Build-Session A — Core Gameplay (TPS + Ability + Ownership)
**Owner focus:** Gameplay systems  
**Goal:** Playable TPS character + working Ability System + basic OwnershipComponent behaviour

**Key tasks:**
- Polish PlayerController + form switching
- Finish HackingAbility + NexFirewallAbility (actual effects)
- OwnershipComponent visual/gameplay switch (even with placeholders)
- TestArena scene fully playable
- Basic Contribution / Knowledge Rank integration

**Definition of Done:**
- Can run TestArena, move, use 2 abilities, switch forms, see ownership change on a test object

---

### Build-Session B — Space + Ship + Colony Seed
**Owner focus:** Space layer  
**Goal:** Flyable ship + basic modular system + simple colony/extractor

**Key tasks:**
- Finish ShipController (semi-Newtonian)
- Basic module attachment
- Simple space test scene
- Resource node + Contribution gain
- Landing transition placeholder (ship → TPS)

**Definition of Done:**
- Can launch, fly, land (or load) into TPS test scene

---

### Build-Session C — Asset Pipeline + VM
**Owner focus:** 3D assets & automation  
**Goal:** Working Tripo → Blender → dual-theme → neon bucket pipeline

**Key tasks:**
- Complete install on Asset VM (Blender headless, deps)
- Implement real Tripo API call in `generate_tripo.py`
- Implement `process_asset.py` (LOD + Cybernex/gROT materials)
- Watcher + sync to `s3://neon/dev/`
- First successful end-to-end asset (even low quality)

**Definition of Done:**
- One asset goes from prompt → Tripo → processed dual variants → appears in `assets/` and in bucket

---

### Build-Session D — Infrastructure & Tooling (optional parallel)
**Owner focus:** CI, docs, developer experience  
**Goal:** Stable foundation for the other sessions

**Key tasks:**
- Improve export jobs reliability
- Better Godot project structure
- AssetLoader improvements
- Documentation cleanup

---

## 3. Agent Role Suggestions for Future Sessions

| Session | Suggested Lead Focus |
|---------|----------------------|
| A (Core Gameplay) | Lucas-style (TPS, Abilities, feel) |
| B (Space) | Harper-style (Ship, physics, modules) |
| C (Assets) | New / technical (pipeline, Blender, Tripo) |
| Overall orchestration | Grok |

---

## 4. Important Constraints & Decisions Already Made

- **No secrets in git** (keys only via env / GitHub Secrets)
- Heavy assets never committed — only in `assets/` + bucket `neon`
- Client must support **macOS + Windows**
- Primary generation service: **Tripo** (free-tier first)
- Dynamic Ownership = dual visual + gameplay profiles (Cybernex / gROT)
- Prefer soft / informational advantages from Knowledge system (no P2W)
- Local-first development, Yandex Cloud for VM + Object Storage

---

## 5. How to Start a New Parallel Session

1. Read this HANDOFF.md + CONCEPT.md + DEVELOPMENT_PLAN.md
2. Choose one Build-Session (A, B or C)
3. Create a short session goal + DoD
4. Work only within that scope
5. Commit frequently with clear messages
6. Update this handoff when the session ends

---

## 6. Immediate Next Actions (when ready)

- Decide which parallel sessions to run first (recommended: A + C)
- For Session C: run the VM install script (to be provided)
- For Session A: continue from current Godot scripts in `godot/scripts/`

---

*End of handoff. Current multi-agent session is stopped.*
