# NAEON — Alliance Diplomacy: War, Truce, Coalition

**Version:** 0.1  
**Depends on:** rules/11 ranks, 03 Ownership, 13 MOBA influence, legal/Fair Play  
**Reference practices:** EVE-style standing clarity + Stellaris-readable states — **without** spreadsheet-only play or permanent map lock from one mode

---

## 1. Intent

Diplomacy is a **strategy/social layer** tool for alliances. It must:

- Make war costly and visible
- Allow de-escalation (truce)
- Enable temporary multi-alliance pressure (coalition) without merging power pools into personal DPS
- Never sell war outcomes via subscription

---

## 2. Standing states (alliance ↔ alliance)

| State | Meaning | Gameplay |
|-------|---------|----------|
| **Neutral** | Default | Normal contested rules |
| **Friendly** | Non-aggression preference | Optional shared dock rights if both set |
| **Allied (bilateral)** | Mutual defense expectation | Shared intel markers (soft); not shared claim ownership |
| **Coalition** | Multi-party temporary war pact vs target(s) | See §5 |
| **At War** | Formal hostility | War objectives, structure damage rules, timer |
| **Truce** | Timed peace after war | No new structure claims vs each other until expiry |

Standings are **alliance-scoped**, set by Rank 4 (Leader) or Rank 3 with policy flag.

---

## 3. Declaring war

| Rule | Value |
|------|--------|
| Who | Rank 4 (or delegated Rank 3) |
| Cost | Alliance pool score sink (band 200–500 starting) + public timer |
| Warm-up | **15–30 min** real-time before full structure siege rights (anti-blast) |
| Visibility | Map banner + notification to target officers+ |
| Mutual war | If B already declared on A, skip duplicate cost |

War does **not** auto-flip Ownership. Claims still use rules/03 presence + investment + Contested resolution.

---

## 4. Truce & surrender

| Action | Rules |
|--------|--------|
| Offer truce | Rank 4; optional score transfer (0 allowed) |
| Accept | Rank 4 of other side |
| Duration | 24–72 h selectable bands |
| Break truce early | Heavy pool penalty + public dishonor flag (Fair Play adjacent) |
| Auto-truce | Optional after N days with no structure damage (anti-zombie war) |

---

## 5. Coalitions

- Temporary pact: 2–N alliances vs listed enemy alliances or Neutral war targets.
- **Does not** merge Contribution/Biomass pools into one combat wallet.
- Shared war objectives / pings only.
- Leader of coalition is rotating or designated; cannot force member alliances to surrender their claims.
- Max concurrent coalition membership soft-capped (e.g. 1 offensive coalition at a time) to reduce blob meta — tune later.

---

## 6. Structure rules under war

- Reinforced timers on major hubs (no instant delete).
- Asset safety: partial cargo risk; full loot wipe only where explicitly designed (not default safe hub).
- Arena War Score still **soft** and capped (rules/13); cannot replace MMO siege presence.

---

## 7. What diplomacy is not

- Not a P2W shop item
- Not a mute on Fair Play reports
- Not permanent uncapturable status for winners
- Not required to play solo/small-gang content (open Contested still exists)

---

## 8. UI / logging

Public war history for involved alliances. Rank 3+ see standing matrix. All war/truce actions logged for moderation.

---

## 9. VS / Phase seed

Standing enum + war declare mock + truce timer is enough for strategy layer prototype; full siege timers later.

---

*Diplomacy source of truth.*
