# NAEON — Shared Agent Memory

**Last updated:** 2026-08-07 (design gaps closed)

## Core constraints
No P2W · soft Knowledge · Infection max 5 · S1 · freemium ≠ power · Tripo-first · narrative ≠ power · perf/25 · site_pin catalog · constructor templates only

## Design corpus
rules/00–26 · Act I–VI + premium · SITE_PIN · **CONSTRUCTOR_TEMPLATES** · **SIDE_QUEST_TEMPLATES** · **EDU_MODULE_LIBRARY** · skill v2.0

## Gaps closed
- Constructor template seed (8 templates, VS = 2)
- Generated side-quest templates
- Edu module library soft
- LEGENDARY_SITES v0.2 with IDs
- HANDOFFS refreshed to skill v2.0 + rules 20–26

## Implementation P0
A: Infection 5 + perf · B: TransitionContext S1 · E: Act I resources · Ops: Tripo/neon

## Protocol
HANDOFF → rules/lore/design → skill §25 → code.

## 2. Current Mechanical Truths

### Factions & Lore
- The Schism originated from conflict among NAEXOS creators.
- gROT split and used the transgalactic network as infection vector.
- Most of humanity is in hibernation in NEX on ARK.
- Noo-people and Cybernex animal-robots are protected by genetic editing (with limitations compensated by RBE/NAEXOS model).

### Key Systems Status
- Ability System: data-driven foundation exists (supports Hacking / Firewall flags).
- OwnershipData + OwnershipComponent: data model and skeleton exist.
- Knowledge / Contribution / Subject Mastery: data structures exist.
- Dynamic Ownership: visual + gameplay transformation required (dual themes).
- Asset Pipeline: Tripo-first, free-tier prioritized, documented.

### Monetization
- Freemium + paid subscription.
- Tokens for AI generation (Yandex GPT / aiNEX).
- Voice channels gated by subscription or achievement.
- Premium quests are narrative-only and must not affect MMO balance.

## 3. Decision Log (append only)

| Date | Decision | Reason |
|------|----------|--------|
| 2026-08-05 | Design Lead role activated | User directive |
| 2026-08-05 | Tripo selected as primary 3D generator | Best balance of topology, price, free tier for game assets |
| 2026-08-05 | Parallel multi-agent build sessions stopped; handoffs created | User directive |
| 2026-08-05 | Shared Agent Memory + Holistic Skill created | User directive |

## 4. Open Questions / To Resolve

- Exact numerical parameters for Hacking duration, Firewall strength, infection progress rates.
- Full list of starting star systems and their ownership rules.
- Concrete soft multipliers for each Subject Mastery in combat.
- Voice channel achievement thresholds.

## 5. How Agents Must Use This Memory

1. Before making any design or mechanical change — read this file.
2. After any significant decision or new rule — append to Decision Log and update the relevant section.
3. Never contradict the Core Project Constraints.
4. Prefer updating existing artifacts over creating conflicting new ones.

---

*This memory is the contract between all agents working on NAEON.*

| 2026-08-06 | Vertical slice asset batch1 complete (10 meshes → dual-theme LODs) via Tripo+Blender; economical A/B/C | Holistic skill |
| 2026-08-06 | Ship/colony/dummy runtime GLB load; Mac DMG installer + AutoUpdater | Session |

## Decision Log — 2026-08-06
- Budget: week 5k / month 20k Tripo; vision not capped after top-up.
- Sysreqs floor: RTX 1060 3GB / i3 / 16GB; tiers LOW–ULTRA in GraphicsQuality.
- Shipped OpenSpace seamless continuum (FloatingOrigin, PlanetBody, ship SCM/NAV/HOVER, surface walk).
- Main scene switched to OpenSpace.tscn.
- Wave S complete; A in progress under week cap.

| 2026-08-06 | BaseBuilder pad streaming + altitude fog; A 2w wave nearly complete | Holistic queue |
| 2026-08-06 | Atmosphere fresnel dual-shell adopted as default (no Bruneton on min spec) | Atmo analysis |\n\n| 2026-08-06 | Pad claim + harvest → Contribution only (soft mastery colony_ops); no combat power from ownership | Holistic |\n\n| 2026-08-06 | OpenSpace: full flight attitude; SurfaceWalker snap; procedural char anim — priority playability | Holistic |\n

| 2026-08-06 | SurfaceDetail procedural patches (code-first, 0 Tripo) | Holistic economical |
| 2026-08-06 | Contested pad ownership with readable dual-threat tint | Dynamic Ownership |
| 2026-08-06 | Infection stacks 1–5 + GameHUD; Firewall cleanse 1; ability CD to param sheet | Ability track A |\n\n| 2026-08-06 | Channeled Hack 1.5s interruptible + Firewall break; pad dual-theme swap on claim resolve | Holistic A/B |\n\n\n| 2026-08-06 | Planet terrain edit NMS-like with volume caps; procedural station/ship interiors (I key); 0 Tripo | Holistic |\n

| 2026-08-06 | Terrain undo+FX; channel VFX; ContestedRing; interior GLB decorate; 0 Tripo autonomous | Holistic |

| 2026-08-06 | Contested HUD banner+radar; terra dust; limb walk; soft Knowledge toasts; Desktop DMG size verify | Holistic economical |\n\n| 2026-08-06 | SoftKnowledge §7.3 + asymmetric Contribution/Biomass + EduQuest pad seed + F9 faction cycle; 0 Tripo | Holistic conceptual |\n\n| 2026-08-06 | Seamless S1 LayerContext + layer HUD; physics lead marker QoL; AllianceRanks 0–4 soft promote; 0 Tripo | Holistic v1.4 |\n\n| 2026-08-06 | Aexion Clash slice + WarScore daily 60 soft influence; Arena layer S1; VERSION 0.3.3; 0 Tripo | Holistic v1.4 |\n\n| 2026-08-06 | Clash 3-lane readability + radar + dual nexus; firewall channel break helper; 0 Tripo | Holistic v1.4 |\n\n| 2026-08-06 | Soft lane objectives pressure 0-100 + alt win 3 lanes; +2 WS/lane; 0 Tripo | Holistic v1.4 |\n\n| 2026-08-06 | Wave C HeroFormCatalog dual-theme + gROT Infector; LayerContextAuthority local stub; 0 Tripo | Holistic v1.4 |\n
| 2026-08-06 | ProceduralLocomotion arena bob + SoftNetSession lag ghost (120ms); 0 Tripo multiplayer prep | Holistic v1.4 |


| 2026-08-07 | Session Contract: batch DMG only; benchmarks SC/NMS+EVE/Stellaris+Predecessor; Phase0 ~5%; Tripo check each iter | Owner |
| 2026-08-07 | Phase 0 feel pass: MainMenu, CombatJuice, AudioDirector, SessionObjectives, pad density | Holistic |


| 2026-08-07 | Planned EVA open-space exit, per-hull interiors (incl. single-seat), OpMode SIEGE morph geometry | Owner + holistic |
| 2026-08-07 | Authority doc docs/systems/SHIP_EVA_INTERIOR_MORPH.md; sprint order EVA→MORPH→INT→NET | Holistic |

| 2026-08-07 | Ground vehicles hangars/ramps planned + CargoHold/Ramp/Rover scaffold | Holistic |
| 2026-08-07 | 0.3.18 combat readability + SurfaceFlora | Holistic |

| 2026-08-07 | S-EVA / S-MORPH / S-INT / V1-V2 code landed; Desktop still 0.3.18 until acceptance → 0.3.19 | Holistic |


## Decision Log — 2026-08-07T23:22:10.485908+00:00
- Parallel content: Tripo A ownership_claim_pylon (high) + B ground_rover_chassis (standard); balance was ~4870.
- Code: ship bolts → Area3D + ProjectileRunner hits; pad claim particles + claim_beacon mesh; siege energy cost up.
- No DMG micro-release.


## 2026-08-07T23:35:35.579344+00:00
- Ability feedback toasts + HUD CD bar; walker full kit keys.
- Tripo B: cybernex_shield_emitter + cargo_landing_container (−40 cr). Balance ~4720.

### 2026-08-08 — ShipHullAmbient
- Code-first hull rim/engine/cabin lights + op_mode pulse (SIEGE/SCAN/land).
- 0 Tripo. Sequential after scan/landscape.


| 2026-08-13 | `s3://neon/generations/` = approved design renders + orthogonal Tripo schemes; index `generations/catalog.json` updated on every ingest | Owner + sequential-dev |
| 2026-08-14 | Phase 0 playtest: AbilitySystem activate, rules/04 costs, enemy scan cache, CombatJuice label pool, site_pin, canon identity cards. No DMG. | sequential-dev |
| 2026-08-15 | Clash HUD collapse (banner/ScoreLine/LaneHUD); ship bolt sweep + hull crit recover + shield hold; pad turrets track hulls. No permadeath, no P2W. | sequential-dev |

