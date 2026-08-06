# NAEON — Ship, Base & Colony Modules (stats)

**Version:** 0.1  
**Depends on:** rules/14 seed, 03 Ownership, 15 economy, 12 crafting  
**Reference bar:** modular expression (NMS/SC feel) within economical budgets — not full sim parity

---

## 1. Ship modules

### Categories & primary stats

| Category | Key stats | Tier band notes |
|----------|-----------|-----------------|
| **Propulsion** | Thrust, torque, fuel efficiency | Higher tier = better accel within soft speed cap |
| **Defense** | Shield HP, recharge, resist profile | CX: Firewall lattice · gROT: spore cloud — **same HP budget** |
| **Offense** | Weapon power, tracking, heat | Shared DPS index by tier (see rules/21) |
| **Utility** | Cargo volume, scanner range, hack/cleanse charges | Tag-aligned with TPS abilities |
| **Carrier** | Drone/fighter capacity (seed) | Fleet aggregation later; LOD for low-end |

### Example rank-1 numbers (VS starting — retune via telemetry)

| Module | Tier | Stat example |
|--------|------|--------------|
| Basic thruster | T0 | Thrust 100, torque 40 |
| T1 thruster | T1 | Thrust 120, torque 50 |
| Shield lattice T1 | T1 | Shield 800, recharge 40/s |
| Spore ward T1 | T1 | Shield 800, recharge 40/s (different VFX/resist lean) |
| Pulse turret T1 | T1 | Power index 1.15, tracking mid |
| Cargo hold T1 | T1 | +20 m³ |
| Hack probe T1 | T1 | 1 charge, applies soft Infection pressure on lock |
| Cleanse beacon T1 | T1 | 1 charge, ally cleanse in 15 m bubble |

Faction flavour **must not** break tier parity.

---

## 2. Multi-crew (later)

Roles: Pilot / Gunner / Engineer. Abilities map to station seats; one player can solo with reduced efficiency — not mandatory multi-crew for viability.

---

## 3. Base & colony modules

| Module | Function | Key stats / cost band |
|--------|----------|------------------------|
| **Extractor T1** | Resource node pull | Yield table rules/15; cost 80–120 score |
| **Extractor T2** | Higher yield | 250–350; upkeep 15/day |
| **Storage** | Shared alliance / personal | Volume; permission-gated (rules/11) |
| **Defense turret** | Auto/manual structure defense | HP, tracking; Ownership-themed VFX |
| **Firewall node / Spore pylon** | Structure Hack resist / Infection pressure | Same fortify budget |
| **Dock / pad** | Land, TransitionContext anchor | Throughput |
| **Factory / vat** | Craft station tier gate | Unlocks T1–T2 recipes |
| **Habitat / décor** | Cosmetic + soft morale UI only | **Zero combat stats** |
| **Constructor beacon** | Alliance template missions | Officer+ only |

### Ownership transform

When claim flips (rules/03): services list, VFX theme, NPC vendors, and defensive kit **skins** swap; numeric budgets stay on the same tier curve unless Contested penalty applies.

---

## 4. Soft caps & upkeep

Unpaid upkeep → efficiency drop → Contested vulnerability (not instant delete). Alliance pool pays hub modules (rules/11, 15).

---

## 5. Fleet LOD rule

~30 ships under flagship = aggregated icons + simplified AI, not 30 full physics bodies on minimum preset.

---

## 6. VS must-have

One attachable propulsion + one defense module on starter hull; one extractor; one claimable pillar with theme swap.

---

*Modules stats authority; expand tables after first space/economy playtest.*
