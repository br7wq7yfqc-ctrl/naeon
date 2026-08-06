# NAEON — Build-Session Briefs (Design-Aware)

**Date:** 2026-08-06  
**Companion:** `docs/HANDOFF.md` (unified snapshot)  
**Canon:** `docs/rules/*`, skill `naeon-holistic-economical` v1.2

Sessions may run unified or parallel. Each brief lists **must-read design**, **current code**, **next tasks**, **DoD**.

---

## Session A — Core Gameplay (TPS / Ability / Ownership feel)

### Must-read design
| Doc | Why |
|-----|-----|
| `00_DESIGN_PILLARS.md` | Constraints |
| `02_ABILITY_SYSTEM_AND_HACKING.md` | Ability model, Hack vs Firewall |
| `04_ABILITY_PARAMETERS.md` | Rank-1 numbers, Infection stacks |
| `03_DYNAMIC_OWNERSHIP_AND_FACTIONS.md` | Claim / Contested |
| `08_KNOWLEDGE_SOFT_EFFECTS.md` | Soft combat UI only |
| `10_UI_INTERFACE_LAYER.md` | TPS HUD contracts |

### Current code
- TestArena playable: movement, form cycle, Pulse / Nex-Firewall / System Probe
- Claimable pillars with Ownership visual blend
- Extractor + resource node → Contribution
- Data-driven Ability scaffolding

### Next tasks (priority order)
1. Align ability resources to `04_ABILITY_PARAMETERS` (channel time, CD, Infection stacks 1–5, Firewall duration/absorption).
2. Make Hacking **interruptible**; Firewall **breaks/slows** channel and cleanses stacks per rules.
3. Infection stack UI pips on target (shape + number); never colour-only.
4. Optional Knowledge overlays (weak-point / hazard) — **off by default**, no auto-aim.
5. Enemy dummy for TTK feel targets (4.5–6.5 s equal skill).
6. Form flavour (Canine / Feline / Avian) within **shared balance budget**.

### DoD
- Playable TPS: Hack vs Firewall readable and interruptible
- Infection 5-stack window feels decisive, not permanent lock
- TestArena stable ~60 FPS low-end preset
- No hard power from Knowledge or shop

---

## Session B — Space / Ships / Ownership objects

### Must-read design
| Doc | Why |
|-----|-----|
| `14_SHIP_AND_SPACE_SEED.md` | Semi-Newtonian, modules, multi-crew later |
| `03_DYNAMIC_OWNERSHIP_AND_FACTIONS.md` | Capitals/stations claim rules |
| `13_MOBA_ARENA_INFLUENCE.md` | Arena cannot permanently flip capitals |
| `10_UI_INTERFACE_LAYER.md` | Space HUD |
| `05_ECONOMY_RBE_BIOMASS.md` | Extractor output by owner |

### Current code
- ShipController: semi-Newtonian flight, modular attach, fire, land → TestArena
- Colony seed: ResourceNode + Extractor + OwnershipComponent

### Next tasks
1. Module categories as data: propulsion / defense / offense / utility / carrier seed.
2. Faction flavour modules (Firewall lattice CX / spore cloud gROT) **same tier budget**.
3. Ownership on one station/outpost: Contested progress ring + service list swap.
4. Space HUD: speed/shield, module hotbar, ownership-tinted brackets.
5. Cargo risk placeholder (logistics loop later).
6. Keep fleet aggregation in mind — no 30 full-fidelity ships on low-end.

### DoD
- Fly, equip modules, land, claim/contest one object with visual theme shift
- SpaceTest playable low-end
- No Arena-only permanent capital flip logic

---

## Session C — Asset Pipeline

### Must-read design
| Doc | Why |
|-----|-----|
| `docs/ASSET_PIPELINE.md` | Pipeline steps |
| `docs/ASSETS_STORAGE.md` / `ASSETS_AUTO_SYNC.md` | neon + local |
| Skill §5 | Economical checklist A/B/C |
| `10_UI_INTERFACE_LAYER.md` | Placeholder UI before final art |

### Current code / ops
- Tripo client + Blender dual-theme LOD processor + `run_pipeline.sh`
- **Blocked:** Tripo balance 0; rclone `neon` keys may be missing on machines

### Next tasks
1. When credits available: one Priority **B** prop → dual Cybernex/gROT variants + LODs.
2. Verify output lands in local `assets/` (gitignored) and optionally syncs to `neon`.
3. Prefer variant materials over second mesh.
4. Document any paid spend in SHARED_AGENT_MEMORY.
5. Do **not** commit binaries or API keys.

### DoD
- One end-to-end: prompt → processed dual-theme asset usable as Godot placeholder
- Pipeline runnable on VM without secrets in git

---

## Session D — Strategy / Alliance / Economy (when staffed)

### Must-read
`05_ECONOMY_RBE_BIOMASS.md`, `11_ALLIANCE_AND_SOCIAL.md`, `12_CRAFTING_AND_BLUEPRINTS.md`, `06_QUEST_SYSTEM.md`

### Next tasks
1. Contribution / Biomass ledgers with **soft daily caps** (use early bands from economy doc).
2. Alliance ranks 0–4 + object permissions (dock/storage/defenses).
3. Constructor templates only; no harassment targets.
4. Crafting layers: components → modules → structures → cosmetics (no combat on décor).

### DoD
- Extract → deliver → small upgrade loop
- Alliance data model with permissions; no pool→combat power conversion

---

## Session E — Quests / Lore / Meta (when staffed)

### Must-read
`06_QUEST_SYSTEM.md`, `07_NPC_QUEST_GIVER_GRID.md`, `docs/lore/CAMPAIGN_ARCS_SEED.md`, `CHARACTER_BIOS_SEED.md`, `docs/legal/*`

### Next tasks
1. Static quest data model + 1 Cybernex + 1 gROT standard quest.
2. Premium quests marked **Story only — no power**.
3. Educational node stub (soft Knowledge only).
4. NPC role IDs from grid for dialogue hooks.

### DoD
- One complete static quest playable; premium path cannot grant claim/combat power

---

## Cross-session rules

- Feature branches: `feature/session-A-…`, etc.
- One writer per hot path when possible (anti-drift).
- After DoD: PR → main; update SESSION_STATUS + SHARED_AGENT_MEMORY.
- Placeholders OK; design numbers in `04_*` / `05_*` are starting points.

---

*Briefs supersede the 2026-08-05 paused-session text. Implementation snapshot wins over older task lists where they conflict.*
