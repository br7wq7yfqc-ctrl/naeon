# NAEON — Seamless Context Payload & Transition Contracts

**Version:** 0.1  
**Status:** Design authority for Session A/B transition work  
**Depends on:** skill `naeon-holistic-economical` §4.1 (S0–S3), rules/10 UI, rules/03 Ownership, rules/06 Quests  
**Reference bar:** Star Citizen (immersion / intentional transitions) — **not** full continuous sim scope

---

## 1. Purpose

When the player moves between layers (Strategy ↔ Space ↔ TPS ↔ Arena), **gameplay context must not silently disappear**. This document defines the payload, stage DoD, and Godot-facing contract.

---

## 2. Layers

| Layer ID | Name | Typical scenes |
|----------|------|----------------|
| `meta` | Boot / character / settings | Login, form select |
| `strategy` | System / galaxy map | Map, orders, alliance overlay |
| `space` | Flight / ship | SpaceTest, open space instances |
| `tps` | Third-person surface / interior | TestArena, hubs, colonies |
| `arena` | Aexion Clash MOBA | Match instance |

Player must always be able to name current layer and exit path (UI layer label).

---

## 3. Context payload schema (S0+)

Serialize at transition start; restore after load. Fields may be null if not applicable.

```text
TransitionContext {
  schema_version: int          // start at 1
  from_layer: enum
  to_layer: enum
  player_id: string
  faction: Cybernex | gROT
  form_id: string?             // animal form / body

  // Objectives
  active_quest_ids: string[]   // e.g. CQ-CX-I-01
  quest_step_hints: map?       // optional step keys only

  // Ownership / claim
  claim_target_id: string?
  claim_state: Neutral|Cybernex|gROT|Contested?
  claim_progress: float?       // 0..1 if Contested

  // Logistics
  cargo_snapshot: [{ item_id, qty }]?
  cargo_risk_flag: bool?

  // Ship / TPS bridge
  ship_id: string?
  dock_or_pad_id: string?
  loadout_hash: string?        // soft check, not full inventory dump

  // Social
  alliance_id: string?
  party_ids: string[]?

  // Arena
  match_id: string?
  war_score_pending: int?      // apply only after authoritative server confirm

  // UX
  show_layer_label: bool       // default true through S1
  fade_style: enum             // standard | combat_safe
}
```

**Rules**
- Server (or local authority in offline slice) is source of truth for quest, claim, cargo.
- Client may speculative-restore UI; reconcile on ready.
- Do not put full inventory or ability cooldowns in payload unless needed for the destination layer — prefer re-fetch from authority.
- `war_score_pending` never grants claim strength client-side alone.

---

## 4. Stage acceptance (expand skill ladder)

| Stage | Required |
|-------|----------|
| **S0** | Payload exists; fade + **layer label**; fields passed; lost context acceptable only if logged as known gap |
| **S1** | Transition wall-clock **< 3 s** on target mid hardware; **no** loss of active_quest_ids, claim_target_id, cargo_snapshot on primary land/dock/undock paths |
| **S2** | Primary hub routes reduce hard loads; Arena enter/exit and long jumps may still instance |
| **S3** | Stretch: continuous feel on hub routes within low-end budget |

Current implementation expectation: **S0** until Session B declares otherwise in HANDOFF.

---

## 5. Primary routes (must preserve context at S1)

1. Space → TPS (land / pad / airlock)
2. TPS → Space (launch / undock)
3. Strategy → Space or TPS (drop-in)
4. Any → Arena (match start): may clear combat state; must restore quest list on return
5. Arena → previous layer: re-apply payload; apply War Score only via server

---

## 6. UI contract

- During load: non-blocking layer chip (`SPACE` / `SURFACE` / `ARENA` / `MAP`) — rules/10.
- On fail/timeout: return to last safe layer with error toast; do not corrupt claim/cargo.
- Combat-safe fade: no full white frame that hides incoming damage telegraphs longer than necessary.

---

## 7. Godot hooks (suggested)

- `TransitionContext` as Resource or Dictionary with schema_version
- `LayerTransitionAutoload.request(to_layer, context)`
- Emit `context_restored` after destination ready
- Test: TestArena ↔ SpaceTest round-trip with quest id + one cargo stack + claim id

---

## 8. Out of scope (do not invent here)

- Full continuous open-world streaming (S3 stretch only)
- Seamless multi-crew body swap across instances without design pass
- Client-authoritative War Score or claim flips

---

*Source of truth for transition context until superseded.*
