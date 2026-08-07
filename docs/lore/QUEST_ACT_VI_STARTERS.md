# NAEON — Act VI Starter Quest Definitions

**Version:** 0.1  
**IDs from:** CAMPAIGN_QUEST_IDS.md  
**Systems:** Alliance (11, 26), Contested (03), soft War Score (13)  
**Sites:** SITE_PIN_CATALOG  
**Constraint:** Climax is multiplayer-ready objective fantasy — **not** single-player free capital flip; Arena influence remains soft-capped

---

## Cybernex — Line in the Reach

### CQ-CX-VI-01 — Alliance Board

| Field | Value |
|-------|--------|
| Giver | `CX_ALLIANCE_BOARD` |
| Layer | Hub |
| Site pins | Alliance hub / ARK board |
| Goal | Open alliance UI; view ranks; optional join or create training alliance |
| Teach | Ranks 0–4 labels (rules/26); pool read-only |
| Reward | Contribution 50–80 |

### CQ-CX-VI-02 — Twin Moon Brief

| Field | Value |
|-------|--------|
| Giver | `CX_WARDEN` |
| Goal | Briefing on Twin Moon A Contested rules; soft War Score explanation |
| Site pins | `SITE_SHATTERED_TWIN_MOON_A` |
| Teach | Contested multiplayer objective; Arena link is soft only (rules/13) |
| Reward | Contribution 70–100 |

### CQ-CX-VI-03 — Contest the Moon

| Field | Value |
|-------|--------|
| Giver | `CX_ALLIANCE_BOARD` |
| Goal | Participate in Contested event on Twin Moon A (or training sim); hold or contest for duration |
| Site pins | `SITE_SHATTERED_TWIN_MOON_A` |
| Teach | Full Ownership pressure loop; alliance constructor optional |
| Reward | Contribution 120–180 (band, not exclusive gear) |
| Perf | Cap participants presentation; LOD fleet (rules/25) |

---

## gROT — Claim for ROT

### CQ-GR-VI-01 — Spire Orders

| Field | Value |
|-------|--------|
| Giver | `GR_ALLIANCE_SPIRE` |
| Layer | Hub |
| Site pins | `SITE_ROT_SPIRE` |
| Goal | Receive Spire orders; open alliance ranks UI |
| Teach | Hierarchy; constructor gate |
| Reward | Biomass 50–80 |

### CQ-GR-VI-02 — Moon B Pressure

| Field | Value |
|-------|--------|
| Giver | `GR_VOICE_OF_ROT` |
| Goal | Briefing Contested climax; loyalty VO; soft War Score framing |
| Site pins | Twin Moon / Contested twin |
| Teach | Climax stakes without pay-win |
| Reward | Biomass 70–100 |

### CQ-GR-VI-03 — Claim Pulse

| Field | Value |
|-------|--------|
| Giver | `GR_ALLIANCE_SPIRE` |
| Goal | Participate in Contested hold/flip pressure to threshold |
| Site pins | Contested moon pin |
| Teach | Swarm claim pressure; no permanent uncapturable from one quest |
| Reward | Biomass 120–180 |

---

## Design rules

- VI-03 is **participation** toward Contested threshold, not instant map paint for solo.
- Soft War Score from Arena never exceeds published daily caps (rules/13).
- Rewards stay in Contribution/Biomass bands — no unique permanent weapons.

---

*Act VI alliance / Contested climax hooks.*
