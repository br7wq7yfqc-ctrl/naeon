# Aexion Clash vertical slice

**Stage:** S1 · **Bar:** Predecessor/Paragon readability + soft world influence  
**Skill:** naeon-holistic-economical v1.4 §4.4

## Rules (implemented)
| Rule | Value |
|------|-------|
| Daily War Score cap | **60** (SoftSession `user://soft_session.json`; further wins → cosmetics / title) |
| Kill WS | 1.5 |
| Match win WS | **15** (rules/13) |
| Match loss WS | **3** (participation) |
| Soft influence | ≤20% of match WS, max 4 — **temporary**, never permanent planet flip |
| Layer | Arena via LayerContext |
| Exit | O → OpenSpace · Tab → SpaceTest |

## Non-goals
Full MOBA lanes, items shop P2W, arena flipping capitals.

## Play
OpenSpace → **M** or **Tab** → TestArena Clash · kill dummies to 5 · soft influence toast

## Camera (AR-A)
- TestArena / Clash hero: over-the-shoulder 3rd person (`PlayerController.apply_clash_ots`)
- Right-shoulder boom, FOV 70, default pitch −8°, clamp blocks top-down RTS
- Same 3 strips; no new map, no travel-mode name, no G5

## Lane readability (0.3.3+)
- TOP +X cyan · MID gold · BOT -X magenta strips + Label3D
- NEXUS Cybernex south (+Z) / gROT north (-Z)
- Lane structures (AR-B): OUTER / MID / INHIB / CORE as live `Turret` HP on the same 60×60; one INHIB per side (core gate); no P2W repair
- OUTER still fires (160 HP, +28 soft pressure); MID/INHIB/CORE take damage; enemy CORE down = soft match win
- ClashRadar Control HUD
- Lane waves (AR-C + AR-T + AR-V): `ClashWaves` timed `CombatDummy` proxies march TOP/MID/BOT toward enemy OUTER; **AR-T seed** is host-authority Pulse 11 with SoftKnowledge / HUD `WAVE` / `MINION` only; **AR-V** mirrors that seed on the opposite Clash lane; hit/be-hit via existing Turret hooks; no shop / P2W / XP-as-power / 13th kit / new GLB
- Jungle camp (AR-D): one off-lane `ClashCamp` (fangtooth-class role, not IP); damageable code-first proxy; soft contest announce; drop = soft WS, not a unique weapon; Knowledge may label only
- Prime camp (AR-J): one additional off-lane `ClashCamp` (prime-class role, not IP) on the same 60×60; same grammar; soft contest announce; drop = soft WS only (not a unique weapon); SoftKnowledge / HUD labels camp / contest / WS
- River (same footprint): `ClashRiver` mid-crossing + inter-lane channels on the existing 60×60 floor; terrain/read, not an objective; no jump pads (OTS camera)
- Kits / module (AR-E): 4 kits × 4 slots (CX Nex/Grid, GR Rot/Spore); one `ClashModuleBench` session `ShipModule.SENSOR` (not a Paragon deck, not cash-shop); Knowledge may label only; forms stay identity
- Session shop seed (AR-K): second session catalog option on that same bench (`ShipModule.CARGO` / Nex Hold). SoftKnowledge / HUD `HOLD` / `NEX HOLD` only. Not a Paragon card. Not cash-shop / P2W / unique weapon. AbilityKitCatalog prior 4 kits stay.
- Fifth kit (AR-L): CX Lattice on the same catalog (Pulse / Lattice Seal / Lattice Probe / Form Cycle). SoftKnowledge / HUD `LATTICE` / `NEX LATTICE` only. Toward Phase-3 6–8 heroes. Prior 4 kits stay. AR-K bench stays.
- Sixth kit (AR-M): GR Vein on the same catalog (Pulse / Vein Claim / Vein Surge / Form Cycle). SoftKnowledge / HUD `VEIN` / `ROT VEIN` only. gROT symmetric to CX Lattice. Prior 5 kits stay. AR-K bench stays.
- Seventh kit (AR-N): CX Prism on the same catalog (Pulse / Prism Seal / Prism Probe / Form Cycle). SoftKnowledge / HUD `PRISM` / `NEX PRISM` only. Cybernex symmetric slot after CX Lattice / GR Vein. Prior 6 kits stay. AR-K bench stays.
- Eighth kit (AR-O): GR Facet on the same catalog (Pulse / Facet Seal / Facet Probe / Form Cycle). SoftKnowledge / HUD `FACET` / `ROT FACET` only. gROT symmetric slot after CX Prism / GR Vein. Prior 7 kits stay. AR-K bench stays.
- Ninth kit (AR-P): CX Helix on the same catalog (Pulse / Helix Seal / Helix Probe / Form Cycle). SoftKnowledge / HUD `HELIX` / `NEX HELIX` only. Cybernex symmetric slot after CX Prism / GR Facet. Prior 8 kits stay. AR-K bench stays.
- Tenth kit (AR-Q): GR Coil on the same catalog (Pulse / Coil Seal / Coil Probe / Form Cycle). SoftKnowledge / HUD `COIL` / `ROT COIL` only. gROT symmetric to CX Helix. Prior 9 kits stay. AR-K bench stays.
- Eleventh kit (AR-R): CX Spire on the same catalog (Pulse / Spire Seal / Spire Probe / Form Cycle). SoftKnowledge / HUD `SPIRE` / `NEX SPIRE` only. Cybernex symmetric slot after GR Coil / CX Helix. Prior 10 kits stay. AR-K bench stays.
- Twelfth kit (AR-S): GR Thorn on the same catalog (Pulse / Thorn Seal / Thorn Probe / Form Cycle). SoftKnowledge / HUD `THORN` / `ROT THORN` only. gROT symmetric to CX Spire. Prior 11 kits stay. AR-K bench stays.
- Minion-wave seed (AR-T): one host-authority lane wave of `CombatDummy` on the same `ClashWaves`. SoftKnowledge / HUD `WAVE` / `MINION` only. Pulse 11. Infection cap 5. Not a unique weapon, XP power, cash-shop, or 13th kit. Catalog stays at 12. FL-N FLEET 15/15 stays.
- Second-lane wave (AR-V): mirrors AR-T on the opposite Clash lane (same host-authority `CombatDummy`, Pulse 11, SoftKnowledge `WAVE` / `MINION`). AR-T stays on its lane. Not a 13th kit. Not XP power. Not another fleet pip. Catalog stays at 12. FL-N FLEET 15/15 stays. AR-U XP/LEVEL stay informational.
- XP/leveling seed (AR-U): SoftKnowledge / HUD `XP` / `LEVEL` on the same `ClashLocalMatch` / `ClashMatchDirector`. Level is informational only — never DPS / Pulse / yield / kit unlock / exclusive module. Rank / XP ≠ power. Infection cap 5. Catalog stays at 12. FL-N FLEET 15/15 stays. AR-T wave stays.
- 3v3 local (AR-F): `ClashLocalMatch` fills six slots on TOP/MID/BOT (host + SoftNet visual `CombatDummy` puppets). Host owns combat. G5 stays closed. Still startable.
- 5v5 local (AR-G): same host + SoftNet path; ten slots on TOP/MID/BOT + AR-D jungle. Default TestArena door. `--clash-3v3` keeps 3v3.
- Pad door (AR-H): occupied unnamed pad `ClashDoor` → TestArena. Not a city-map. G5 cluster stays closed.
- Match end (AR-I): either team's CORE Turret HP → 0 ends 3v3 and 5v5. SoftKnowledge HUD `WIN` / `LOSS` only. SoftSession records WS (+15 / +3, daily cap 60). Excess wins → `TITLE` cosmetics only. Not planet flip. Not a unique combat item. AR-J does not change this.

## Soft lane objectives
| Action | Pressure | Soft WS |
|--------|----------|---------|
| Kill on lane | +12 | via kill WS |
| Near gROT nexus | +1.2–3.5 /0.25s | — |
| Forward of z=-10 | +0.8 /0.25s | — |
| Lane hits 100 | claim once | **+2** |
| All 3 lanes | match win | win WS |
| Off-lane camp down | +18 MID | **+2** (not a unique weapon) |
| Prime camp down | +24 MID | **+3** (soft WS only; not a unique weapon) |

Never permanent map control. Daily WS still capped at 60.
