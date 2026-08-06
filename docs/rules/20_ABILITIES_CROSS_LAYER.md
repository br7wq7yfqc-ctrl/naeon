# NAEON — Abilities Cross-Layer (beyond pure MOBA)

**Version:** 0.1  
**Depends on:** rules/02, 04, 16, 14, 10  
**Constraint:** Same Ability System Resource model everywhere; MOBA kits are a **subset**, not a separate power track

---

## 1. Intent

One data-driven Ability System serves:

| Layer | Ability use |
|-------|-------------|
| **TPS** | Full combat kit: weapon skills, Hack/Firewall, mobility, utility |
| **Space** | Module-triggered + pilot abilities (hack probe, cleanse beacon, focus fire) |
| **Strategy** | Command abilities (bandwidth cost): claim pressure, fleet orders seed, structure harden |
| **Arena (MOBA)** | Hero kits drawn from same tags; items separate (soft influence only) |

No layer grants exclusive permanent DPS that other layers cannot answer.

---

## 2. Ability slots (TPS baseline)

| Slot | Role | Examples |
|------|------|----------|
| Primary | Weapon skill / basic attack enhancer | Pulse Bolt, Biomass Spike |
| Secondary | Signature faction (Hack **or** Firewall line) | Infect Link / Nex Barrier |
| Mobility | Dash, short reposition | Dash |
| Utility | Heal, reveal, cargo tools, cleanse lite | Repair Nanites, Scanner Pulse |
| Ultimate (soft) | High CD, high cost — not MOBA-only exclusive power | Rank-gated variants of signature |

Loadout swap at safe zones / ship interior only (not mid-duel).

---

## 3. Shared tags

`Hack`, `Firewall`, `Infection`, `Cleanse`, `Mobility`, `Heal`, `Reveal`, `Structure`, `Fleet`, `Support`

Space and Strategy abilities **prefer the same tags** so UI silhouettes and counterplay stay readable (skill §3).

---

## 4. Non-MOBA signature examples (VS → expand)

### Cybernex

| ID | Layer | Effect (rank 1 band) |
|----|-------|----------------------|
| `nex_barrier` | TPS | Cleanse all Infection ≤5; short immunity (rules/04) |
| `lattice_harden` | Strategy | Node resists next 2 hacks (60 s CD) |
| `cleanse_beacon` | Space utility | AOE cleanse pulse on allies in formation |
| `repair_nanites` | TPS | Small HoT |

### gROT

| ID | Layer | Effect (rank 1 band) |
|----|-------|----------------------|
| `infect_link` | TPS | Channel → Infection stack (max 5) |
| `claim_spore` | Strategy | −25% claim gain on target node 20 s |
| `hack_probe` | Space | Soft lock + Infection pressure on ship subsystem |
| `biomass_spike` | TPS | Burst + minor slow |

---

## 5. Counterplay rules (all layers)

1. Channels interruptible.
2. Firewall answers Hack; never permanent immunity.
3. Structure abilities visible on map/UI (Contested, harden icons).
4. Knowledge may clarify tooltips — never unlock exclusive combat slots.

---

## 6. Progression

Ranks 1–5 per signature line (rules/16). Generic abilities gain minor cost/CD polish only — no hidden +30% damage tiers.

---

## 7. Godot

`Ability` Resource + `AbilitySystem` component; layer mask field (`tps|space|strategy|arena`). HUD filters by current layer.

---

*Cross-layer ability authority; MOBA remains rules/13 + kit reuse.*
