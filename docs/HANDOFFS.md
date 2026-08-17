# NAEON — Build-Session Briefs (Design-Aware)

> **2026-08-17:** очередь — `docs/design/OPEN_SPACE_SC_BENCHMARK.md` (OS-A). Эти брифы исторические. Не стартовать G2–G6 отсюда. G1 только если OS-C упрётся в масштаб. llvmpipe ≠ FPS PASS.

**Date:** 2026-08-07  
**Companion:** `docs/HANDOFF.md`  
**Skill:** `naeon-holistic-economical` **v2.0**  
**Canon:** rules/00–26 · lore Act I–VI · SITE_PIN_CATALOG

---

## Session A — Core Gameplay (TPS / Ability)

### Must-read
`02`, `04`, `16`, `20`, `21`, `03`, `08`, `10`, **`25`**, skill Infection **max 5**

### Tasks
1. Infection **5** pips (shape + number).
2. Ability costs/CDs from 04 + ranks 16.
3. Interruptible Hack; Firewall cleanse.
4. Knowledge overlays optional, off by default.
5. **Perf smoke** every merge (25): ~60 FPS min preset, no memory climb, free on exit.

### DoD
Readable Hack/Firewall; 5-stack decisive not permanent; perf baseline on TestArena.

---

## Session B — Space / Transitions

### Must-read
`14`, `22`, `03`, `13`, `10`, **`18`**, **`25`**, SITE_PIN_CATALOG

### Tasks
1. `TransitionContext` round-trip TestArena ↔ SpaceTest.
2. Preserve `active_quest_ids`, cargo, claim, **`site_pin_id`**.
3. Layer label; S1 <3 s no hitch.
4. One modular attach; Contested ring.

### DoD
Fly, land, context intact; S1 declared; perf on SpaceTest.

---

## Session C — Assets

### Must-read
ASSET_PIPELINE, skill economical, **25** (LOD)

### Blocked
Tripo / neon — placeholders OK.

### DoD
Dual-theme prop when credits exist; no secrets in git.

---

## Session D — Economy / Alliance

### Must-read
`05`, `15`, `11`, `12`, **`26`**, `23`, `24`, CONSTRUCTOR_TEMPLATES

### Tasks
1. Ledgers soft caps.
2. Ranks 0–4 UI from 26.
3. Constructor: `CT_DELIVER_HUB` + `CT_DEFEND_CLAIM` minimum.

### DoD
Pool deposit; rank list; one constructor template live.

---

## Session E — Quests / Meta

### Must-read
`06`, `07`, `09`, `19`, CAMPAIGN_QUEST_IDS, QUEST_ACT_I–VI, SIDE_QUEST_TEMPLATES, EDU_MODULE_LIBRARY, PREMIUM_EPILOGUES

### Tasks
1. Quest Resources **CQ-CX-I-01** + **CQ-GR-I-01** first.
2. site_pin from catalog only.
3. Premium badge `story_only`.
4. Optional: one SQ_GATHER, EDU_HIST_SCHISM_01.

### DoD
One CX + one GR Act I playable; premium cannot grant power.

---

## Cross-session

One writer per hot path; after DoD → SESSION_STATUS + SHARED_AGENT_MEMORY.  
**Every code track:** rules/25 performance.
