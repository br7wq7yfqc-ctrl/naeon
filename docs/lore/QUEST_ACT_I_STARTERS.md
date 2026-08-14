# NAEON — Act I Starter Quest Definitions

**Version:** 0.1  
**IDs from:** CAMPAIGN_QUEST_IDS.md  
**Givers from:** rules/07  
**Rewards:** standard Contribution/Biomass bands (rules/15); no premium power

---

## CQ-CX-I-01 — Perimeter Sweep

| Field | Value |
|-------|--------|
| Faction | Cybernex |
| Giver | `CX_PATHFINDER` or `CX_WARDEN` |
| Layer | TPS |
| Goal | Visit 3 perimeter beacons; defeat or bypass 2 hostile drones (dummy AI) |
| Teach | Move, camera, basic Pulse, map pings |
| Reward | Contribution 40–60; minor repair nanites cosmetic charge optional |
| Fail | Soft — return to giver |

**Completion script note:** unlocks dialogue for CQ-CX-I-02.

---

## CQ-CX-I-02 — First Cleanse

| Field | Value |
|-------|--------|
| Giver | `CX_MEDICAE` |
| Goal | Apply Nex-Firewall once; cleanse a staged Infection prop (1–2 stacks) |
| Teach | Firewall silhouette, cleanse, Infection pips readable |
| Reward | Contribution 50–70 |

---

## CQ-CX-I-03 — Infection Signature

| Field | Value |
|-------|--------|
| Giver | `CX_WARDEN` |
| Goal | Identify an Infected target (UI); survive or interrupt one Hack channel |
| Teach | Counterplay loop Hack vs Firewall |
| Reward | Contribution 60–80 |

---

## CQ-GR-I-01 — Blood Mark

| Field | Value |
|-------|--------|
| Faction | gROT |
| Giver | `GR_PACK_LEADER` |
| Layer | TPS |
| Goal | Eliminate 3 marked prey dummies; return to pack beacon |
| Teach | Aggression, basic Biomass Spike / Pulse equivalent |
| Reward | Biomass progress 40–60 |

---

## CQ-GR-I-02 — First Channel

| Field | Value |
|-------|--------|
| Giver | `GR_INFECTION_ADEPT` |
| Goal | Land Infect Link on training pylon; hold until 1 stack applies |
| Teach | Hack channel, interrupt risk, stack pip |
| Reward | Biomass 50–70 |

---

## CQ-GR-I-03 — Stack the Prey

| Field | Value |
|-------|--------|
| Giver | `GR_INFECTION_ADEPT` |
| Goal | Reach 3 stacks on a durable dummy before cleanse window (or win the race) |
| Teach | Stack pressure vs Firewall fantasy |
| Reward | Biomass 60–80 |

---

## Implementation

- Quest Resources keyed by ID; giver role_id; objectives as data.
- Premium epilogues not in Act I starters.
- Use TransitionContext (rules/18) if quest spans land/dock later acts.

---

*First playable campaign hooks for Session E / TestArena narrative.*
