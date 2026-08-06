# NAEON — Build-Session Briefs (Design-Aware)

**Date:** 2026-08-06  
**Companion:** `docs/HANDOFF.md`  
**Canon:** docs/rules/* · skill `naeon-holistic-economical` **v1.6**

---

## Session A — Core Gameplay (TPS / Ability)

### Must-read
`00`, `02`, `04`, `16`, `03`, `08`, `10`, skill Infection max **5**

### Next tasks
1. Unify Infection stacks to **5** pips (shape + number).
2. Align costs/CDs to `04` + rank curve `16`.
3. Interruptible Hack; Firewall breaks/cleanses per rules.
4. Knowledge overlays optional, off by default (`08`).
5. Wire Act I tutorial objectives from `lore/QUEST_ACT_I_STARTERS.md` when ready.

### DoD
Hack vs Firewall readable; 5-stack window decisive not permanent; ~60 FPS low-end; no Knowledge hard power.

---

## Session B — Space / Ships / Ownership / Transitions

### Must-read
`14`, `03`, `13`, `10`, `05`, **`18_SEAMLESS_CONTEXT_PAYLOAD`**, skill S0–S3

### Next tasks
1. Implement `TransitionContext` Resource (schema v1 in rules/18).
2. Round-trip TestArena ↔ SpaceTest: preserve quest ids + cargo snapshot + claim id.
3. Layer label chip during load (S0 minimum).
4. Module data categories; Contested ring on one object.
5. Declare stage **S0** or **S1** in HANDOFF when done.

### DoD
Fly, land, contest one object; context not silently dropped on primary route; no Arena-only capital flip.

---

## Session C — Assets

### Must-read
ASSET_PIPELINE, skill economical checklist

### Blocked
Tripo balance / neon keys — placeholders OK.

### DoD
One dual-theme Priority B prop when credits exist; no binaries/keys in git.

---

## Session D — Economy / Alliance

### Must-read
`05`, `15`, `11`, `12`

### Next
Ledgers + soft caps; ranks 0–4; constructor templates only.

---

## Session E — Quests / Meta

### Must-read
`06`, **`07`**, `09`, CAMPAIGN_QUEST_IDS, **QUEST_ACT_I_STARTERS**, **`19`** freemium badges

### Next
1. Quest Resource for CQ-CX-I-01 and CQ-GR-I-01.
2. Premium badge `label.story_only` on any premium stub.
3. NPC role_id on dialogue nodes.

### DoD
One CX + one GR starter quest playable; premium cannot grant power.

---

## Cross-session

Feature branches; one writer per hot path; after DoD update SESSION_STATUS + SHARED_AGENT_MEMORY.  
Freemium copy keys: rules/19. Transitions: rules/18.
