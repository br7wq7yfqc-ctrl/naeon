# NAEON — Act III Starter Quest Definitions

**Version:** 0.1  
**IDs from:** CAMPAIGN_QUEST_IDS.md  
**Systems:** Ownership Contested (rules/03), Infection/Firewall (04/16), ranks (11)  
**Sites:** SITE_PIN_CATALOG  
**Constraint:** No exclusive permanent DPS; claim progress uses published timers; **perf** — capped attackers (rules/25)

---

## Cybernex — Cracks in the Ring

### CQ-CX-III-01 — Contested Module

| Field | Value |
|-------|--------|
| Giver | `CX_WARDEN` (Aegis / Helix VO optional) |
| Layer | TPS |
| Site pins | Training Contested pillar near **Ring of Quiet Lights** (`SITE_ARK_RING`) |
| Goal | Enter Contested zone; observe progress ring; contribute defend ticks OR interrupt one enemy channel |
| Teach | Contested state, progress UI, Ownership readability |
| Reward | Contribution 90–130 |
| Fail | Soft — Contested state continues server-side |

### CQ-CX-III-02 — Hold the Lattice

| Field | Value |
|-------|--------|
| Giver | `CX_WARDEN` |
| Goal | Hold allied claim progress above threshold for N seconds against dummy pressure waves (max concurrent dummies declared) |
| Site pins | Same Contested module or `SITE_ARK_VAULT_CROWN` outer claim |
| Teach | Defend claim loop; Firewall/cleanse under pressure |
| Reward | Contribution 100–140 |

### CQ-CX-III-03 — After-Action Nex

| Field | Value |
|-------|--------|
| Giver | `CX_MEDICAE` |
| Goal | Cleanse residual Infection stacks on self/ally prop; report Integrity |
| Site pins | Med bay near Vault approach |
| Teach | Post-fight cleanse; Integrity/Nex fantasy |
| Reward | Contribution 70–100 |

---

## gROT — Voice and Vein

### CQ-GR-III-01 — Hierarchy Test

| Field | Value |
|-------|--------|
| Giver | `GR_VOICE_OF_ROT` (Third Throat VO optional) |
| Layer | TPS / hub |
| Site pins | `SITE_ROT_SPIRE` approach |
| Goal | Complete loyalty beat: stand at Voice marker; accept pack order (dialogue); no combat power grant |
| Teach | Hierarchy flavour; rank fantasy without paywall |
| Reward | Biomass 70–100 + optional title seed |

### CQ-GR-III-02 — Break the Lattice

| Field | Value |
|-------|--------|
| Giver | `GR_INFECTION_ADEPT` (Graft VO optional) |
| Goal | Win staged Hack vs Firewall duel vs training Warden dummy (reach 3+ stacks or interrupt cleanse) |
| Site pins | Outer ROT Contested training lane |
| Teach | Full counterplay loop under pressure |
| Reward | Biomass 100–140 |

### CQ-GR-III-03 — Vein Open

| Field | Value |
|-------|--------|
| Giver | `GR_PACK_LEADER` |
| Goal | Apply sustained stack pressure on claimable training node; hold Infect window |
| Site pins | Contested drip node / `SITE_ROT_KILNS` outer |
| Teach | Stack pressure as Ownership tool (not free permanent flip) |
| Reward | Biomass 90–130 |

---

## Design rules

- Contested timers and claim bands from rules/03 — do not invent faster flip for campaign.
- Dummy counts **must** declare max concurrent (rules/25).
- Act III is Ownership literacy, not gear unlock gate.

---

*Act III Contested / hierarchy hooks for Session E.*
