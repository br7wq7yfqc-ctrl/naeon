# NAEON — Handoffs for Parallel Build Sessions

**Date:** 2026-08-05  
**Status:** All sub-agents paused. Ready for parallel independent sessions.

---

## Current Project State (Snapshot)

### Repository
- https://github.com/br7wq7yfqc-ctrl/naeon
- Main branch is up to date with CONCEPT.md (v1.2+), DEVELOPMENT_PLAN.md (v2.0), CI, asset pipeline docs.

### Already Implemented
- Godot 4.3 project skeleton (`godot/`)
- `PlayerController.gd` (TPS movement + form switch skeleton)
- Data-driven Ability System (`Ability.gd` + `AbilitySystem.gd`) with Hacking / Nex-Firewall flags
- `OwnershipData.gd` + basic Contribution / KnowledgeRank
- Asset storage strategy (Yandex Object Storage bucket `neon`)
- Sync scripts + `.gitignore` protection for `/assets/`
- CI pipeline (validate + headless + export jobs for Linux/Windows)
- Tripo-first low-cost Asset Pipeline documentation

### Infrastructure
- Yandex Object Storage bucket: `neon`
- Service account with storage.editor rights exists
- Asset Pipeline VM exists (public IP was provided, but no permanent agent access)
- Tripo API key available (user-side only)

---

## Parallel Build Sessions — Handoffs

### Session A — Core Gameplay & Ability Systems
**Owner focus:** TPS, Ability System, Hacking/Firewall, Combat feel, Educational soft integration

**Current status:**
- Basic TPS controller exists
- Ability System is data-driven and supports asymmetric flags
- Hacking / Nex-Firewall exist as concept + flags

**Next concrete tasks:**
1. Polish Ability resource format and activation flow
2. Implement real Hacking ability (TPS) and Nex-Firewall counter
3. Create simple TestArena scene for combat testing
4. Soft Knowledge Mastery combat insights (QoL only)
5. Basic form-specific movement (Canine / Feline / Avian)

**Definition of Done:**
- Playable TPS character with 2–3 working abilities including Hacking vs Firewall
- Test scene loads and runs at 60 FPS on low-end settings

---

### Session B — Space, Ships & Ownership
**Owner focus:** ShipController, modules, carriers seed, Dynamic Ownership Transformation

**Current status:**
- OwnershipData resource exists
- No full ShipController yet
- Dynamic Ownership design is documented

**Next concrete tasks:**
1. Implement `ShipController.gd` (semi-Newtonian flight)
2. Basic modular system (Module resource + attach points)
3. OwnershipComponent with transition_progress
4. Simple visual theme swap (material blend Cybernex ↔ gROT) on one object
5. Space test scene

**Definition of Done:**
- Flyable ship placeholder
- One claimable object that can switch faction visually and in data

---

### Session C — Strategy, Alliance & Economy
**Owner focus:** Colony, Contribution, RBE, Alliance hierarchy, Knowledge system

**Current status:**
- Contribution and KnowledgeRank skeletons exist
- RBE philosophy documented

**Next concrete tasks:**
1. ResourceNode + basic extractor
2. Contribution score calculation
3. Alliance hierarchy data model + permissions
4. Knowledge Rank progression + soft rewards
5. Simple Strategy overlay / orders skeleton

**Definition of Done:**
- Place an extractor, gain Contribution
- Alliance data structure with roles and shared resources

---

### Session D — Asset Pipeline & Tooling
**Owner focus:** Tripo automation, Blender processing, dual-theme variants, VM bootstrap

**Current status:**
- Documentation ready (`docs/ASSET_PIPELINE.md`)
- Storage + sync scripts ready
- Tripo chosen as primary generator

**Next concrete tasks:**
1. Complete `generate_tripo.py` (API call + download)
2. Blender headless `process_asset.py` (LOD + dual materials)
3. `make_faction_variants.py`
4. Full VM install script (user runs it)
5. Inbox watcher

**Definition of Done:**
- One command: prompt → Tripo → processed dual-theme assets in `assets/` + synced to `neon`

---

### Session E — Platform, Quests, Voice & Meta
**Owner focus:** Quest system, Educational nodes, Voice (SpeechKit / Alice), NAEXOS.ONLINE gates

**Current status:**
- Design fully documented in CONCEPT.md
- No runtime implementation yet

**Next concrete tasks:**
1. Quest data model + simple static quests
2. Educational Learning Node UI skeleton
3. Prompt Studio / aiNEX placeholder
4. Voice pipeline architecture (modular STT/TTS)
5. Alliance Quest Constructor design implementation start

**Definition of Done:**
- One complete static quest + one educational puzzle node playable

---

## How to start a parallel session

1. Create a feature branch: `feature/session-A-abilities`, etc.
2. Work only within the scope of that handoff
3. Keep commits small and focused
4. Update this HANDOFFS.md when a session reaches its DoD
5. Merge via PR into `main` after review

## Global Rules (still active)

- Never commit secrets / API keys / `.env`
- `/assets/` stays gitignored
- Prefer soft, non-P2W mechanics
- Local-first, then Yandex Cloud
- Cross-platform (Mac + Windows)

---

*All sub-agents are now stopped. Parallel sessions can be started independently using the handoffs above.*
