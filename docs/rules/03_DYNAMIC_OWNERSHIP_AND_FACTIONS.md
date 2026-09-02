# 03 — Dynamic Ownership Transformation & Faction Asymmetry

**Version:** 0.1  
**Last updated:** 2026-08-05

## Purpose
Claimable objects change both visually and mechanically according to controlling faction. Core differentiator of NAEON.

## Ownership States
NEUTRAL | CYBERNEX | GROT | CONTESTED

OwnershipData: current/previous faction, transition_progress (0→1), claim_strength, owner_alliance_id, last_claim_time.

**DO-A seed (built):** one occupied unnamed pad starts/advances a contested Cybernex ↔ gROT transition (`OwnershipData` + `OwnershipComponent` + `ContestedRing`). SoftKnowledge / HUD labels `CONTESTED` / `CYBERNEX` / `GROT` only — never DPS / yield / thrust / Pulse / Hack. Host authority. ST-F instant flip stays. Not HyperGate G4. Not galaxy-wide transforms.

**DO-B seed (built):** second object — the existing ST-E player orbital cluster (dock+habitat, Nex-Prime orbit) starts/advances the same contested Cybernex ↔ gROT transition. ST-G factory stays. DO-A pad path stays. Same SoftKnowledge labels. Host authority. Not HyperGate G4. Not galaxy-wide transforms.

## Visual Transformation
- Cybernex: clean futuristic + living nature, cyan/white/green emission, Venus Project harmony
- gROT: industrial post-apocalyptic, biomass overlays, red-purple emission, swarm aesthetics
- Contested: mixed / glitching
- Neutral: base / ancient state

Driven by transition_progress (shaders, materials, particles).

## Gameplay Transformation
Services, vendors, resource output, NPC behaviour, defensive kits, quests, docking rights, visual identity of produced units.

## Claiming Rules
1. Presence + appropriate resource expenditure + time.
2. Fighting → CONTESTED.
3. Full transformation only after secure hold duration.
4. Arena/War Score gives temporary claim_strength only (soft, capped).

## Faction Asymmetry
| Axis | Cybernex | gROT |
|------|----------|------|
| Fantasy | Protection, harmony | Assimilation, growth |
| Economy | Contribution + RBE | Biomass Rank |
| Signature | Nex-Firewall | Cyber-Hacking |
| Visual | Clean luminous | Dark biomass |

Both factions must remain viable in all major modes.

## Balance Constraints
No permanent uncapturable objects without extreme visible investment. Transition time allows reaction but keeps map dynamic. Soft Arena influence always capped.
