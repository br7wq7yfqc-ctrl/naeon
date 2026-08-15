# NAEON — Galaxy layer plan

**Status:** design authority for star systems, hyperspace, gates, the galaxy map
and arena entry. **Version 1.0, 2026-08-15.**

Owner brief: planets must be naturally spread around their star; add hyperspace
travel between systems the way Elite Dangerous does it, with hyperdrives; every
system carries gates to its neighbours; add a galaxy map and navigation; let the
player enter the arena from the OpenSpace map.

This document is the plan. What is already built is marked **DONE**; everything
else is specified to the point where it can be implemented without another
design pass.

---

## 1. Why this shape

Three constraints drive every number below.

1. **Lore first.** NAEXOS built a transgalactic network. The Schism happened
   among its creators, and gROT used that network as an **infection vector**
   (`docs/SHARED_AGENT_MEMORY.md`, "Current Mechanical Truths"). So gates are not
   generic sci-fi furniture — they are NAEXOS relics, and a gate is exactly where
   Infection should arrive from. That gives gate ownership real stakes.
2. **Low-end target.** ~60 FPS on the minimum preset, no monotonic memory climb
   (rules/25). One system is loaded at a time; the galaxy is data, not geometry.
3. **No pay-to-win, soft Knowledge.** Fuel, jump range and gate access are
   earned or spatial, never purchased. Knowledge may *inform* navigation (better
   route readouts, hazard warnings) and must never extend range or cut charge
   time. See §9.

---

## 2. Scale ladder

Distances are Godot units, treated as metres. The existing continuum already
works at these magnitudes: `FloatingOrigin` rebases at 2500, planet radii are
420–1400, atmospheres 40–320.

| Tier | Range | How you cross it |
|------|-------|------------------|
| Surface / interior | 0 – 1 km | walk, rover |
| Orbit and approach | 1 – 3 km | SCM 55 m/s, HOVER 22 m/s |
| Inner system | 3 – 15 km | NAV 180 m/s |
| Full system | 15 – 60 km | **CRUISE** (§4.3), target ~4 km/s |
| Interstellar | light-years, abstract | **HYPERSPACE** (§5) or a **GATE** (§6) |

### 2.1 Current system, ARK — **DONE**

`godot/scripts/world/StarSystemCatalog.gd` authors the layout; `PlanetProfileCatalog`
keeps the physical envelopes.

| Body | Orbit | Angle | Inclination |
|------|-------|-------|-------------|
| Star **Aex** (G, r=900) | 0 | — | — |
| Nex-Prime (Cybernex) | 3800 | 24° | 0° |
| ROT-Hive (gROT) | 7400 | 158° | +6.5° |
| Shard-Moon (neutral) | 11800 | 268° | −9° |
| Asteroid belt | 9000 – 10400 | ring | ±210 thickness |
| Gate → ROT-Prime | 13600 | 312° | +3° (authored, not spawned) |
| Gate → Helios Reach | 13600 | 84° | −4° (authored, not spawned) |
| Gate → Echo Ruins | 15200 | 200° | +11° (dormant) |

Distinct angles stop the bodies lining up; distinct inclinations stop them
sharing one plane. The star is a real emissive body, each planet takes its light
direction from it, and the shadow light aims along the star→observer line.

**Target scale once CRUISE exists:** multiply orbits by ~2.8 (Nex-Prime ≈ 10600,
Shard-Moon ≈ 33000, gates ≈ 38000–42000). Holding the current scale until then is
deliberate: at NAV 180 m/s the outer gate would already be a 4-minute hold of W.

---

## 3. Data model

Everything below is authored data, not scene geometry. One system's bodies exist
as nodes; the rest of the galaxy is a dictionary.

```
StarSystemCatalog          # per-system layout: star, bodies, belt, gate anchors
GalaxyCatalog              # NEW: systems, coordinates in light-years, links
  systems: {
    id: {
      display, faction_bias, security, economy,
      coord: Vector3,        # light-years, galactic frame
      bodies_ref: "ARK",     # which StarSystemCatalog entry to load on arrival
      gates: [ {to, state} ],
      services: [pad, refuel, repair, arena, market],
      discovered: bool,      # per save
    }
  }
NavState (autoload)         # NEW: current system, plotted route, jump target,
                            # fuel, discovered set, gate unlock set
HyperdriveModule            # NEW ShipModule type: class, range_ly, fuel_per_ly,
                            # charge_sec, mass_lock_factor
```

`GalaxyCatalog` seeds from `docs/lore/STAR_SYSTEMS_SEED.md`: ARK, ROT-Prime,
Shattered Corridor, Helios Reach, Veil Reach, Mirror Expanse, Forge Depths,
Echo Ruins. Coordinates are authored so that faction heartlands sit apart and
the contested belt lies between them — the map should read politically at a
glance.

---

## 4. Flight tiers

### 4.1 Existing — **DONE**

SCM (55 m/s, combat), NAV (180 m/s, transit, locked in dense atmosphere),
HOVER (22 m/s, VTOL, altitude hold). Honest land gate with a readable envelope
(`land_readiness_line()`).

### 4.2 What is missing

Nothing crosses a full system, and nothing leaves one.

### 4.3 CRUISE — in-system superluminal

The Elite "supercruise" analogue. **Not** a menu teleport: you fly it.

- Entry: `4` from NAV, needs the hyperdrive online, ≥1 fuel, and **no mass lock**.
- Speed: continuous 200 m/s → 4 km/s, throttle-scaled, with a visible warp
  tunnel and a strong FOV/vignette shift so the mode reads instantly.
- **Mass lock:** within `2.5 × (body radius + atmosphere)` of any planet or
  station, CRUISE cannot engage and drops if already engaged. This is the whole
  pacing tool — it forces a real approach to every destination.
- Exit: `4` again, or automatically on mass lock. Exit velocity carries over
  clamped to NAV top speed, so dropping out next to a station is not a crash.
- Fuel: 0.05 units/min. Effectively free; the cost is time and vulnerability.
- Interdiction (later phase): a hostile can pull you out. Hooks reserved, not
  specified here.

**DoD:** cruise from Nex-Prime orbit to the outer gate anchor in under 30 s, mass
lock refuses engagement inside a planet's approach envelope, and the drop-out
leaves the ship controllable.

### 4.4 HYPERSPACE — interstellar

See §5.

---

## 5. Hyperdrive and hyperspace

### 5.1 The module

A new `ShipModule.ModuleType.HYPERDRIVE`, one hardpoint (the audit's
one-per-type rule applies).

| Class | Range | Fuel / ly | Charge | Notes |
|-------|-------|-----------|--------|-------|
| Relay-1 (starter) | 8 ly | 1.0 | 6.0 s | Scout default |
| Relay-2 | 14 ly | 1.4 | 7.5 s | |
| Nex-Lattice (CX) | 20 ly | 1.2 | 9.0 s | Lower fuel, slower charge |
| Spore-Fold (gROT) | 20 ly | 1.6 | 6.5 s | Faster charge, thirstier |

Faction classes are **mirrored, not stronger** — same tier budget, different
shape (rules/04 §2). Range scales down with cargo mass so a loaded hauler jumps
shorter, which is the honest counterpart to the ship's existing cargo system.

### 5.2 Jump sequence

Six states, each visible on the HUD. A jump the player cannot read is the same
defect class as the illegible land gate the audit fixed.

1. **TARGET** — a system is selected in the galaxy map and is within range.
2. **ALIGN** — nose within 15° of the target vector. The HUD shows the cone.
3. **CHARGE** — hold; `charge_sec`, interruptible by taking the drive offline.
   Cannot charge while mass-locked.
4. **JUMP** — 3 s tunnel; input locked; this is the only non-interactive window,
   and it is short on purpose.
5. **ARRIVAL** — you exit near the destination star with the drive on cooldown
   (12 s) and heat elevated. Arrival is always **star-adjacent**, so "fuel
   scooping" and "arrival heat" have a natural home later.
6. **COOLDOWN** — no second jump until it clears.

Failure cases, all non-lethal per the project's no-permadeath rule:
- **Out of fuel:** jump denied with the deficit named ("need 4.2, have 2.8").
- **Out of range:** denied with the shortfall in light-years.
- **Misjump** (only if the drive is damaged): arrive at a *neighbouring* system
  with a damaged drive and a hull-critical style recovery, never a loss.

### 5.3 Fuel

- Tank on the hull, refuelled at any owned pad, free at your own faction's, at a
  cost at neutral, unavailable at hostile.
- Scooping from a star (later phase) is the fallback that keeps a stranded player
  from being stuck — the arrival point being star-adjacent is what makes it work.
- **A stranded player is never dead.** With zero fuel and no pad, a distress beacon
  offers a one-way tow to the nearest owned pad. Costs time, not progress.

**DoD:** jump ARK → ROT-Prime, watch every state on the HUD, arrive at the star,
land, refuel, jump back. Deny out-of-range and out-of-fuel with the numbers named.

---

## 6. Gates

Gates are the second way to travel and the more interesting one, because they are
**objects in the world that can be owned and fought over**.

### 6.1 What they are

NAEXOS relay rings, predating the Schism. Fixed pairs. Crossing one is cheap and
needs no hyperdrive, which makes gates the route for haulers, new players and
anyone out of fuel.

### 6.2 States

| State | Meaning | Effect |
|-------|---------|--------|
| **Open** | Powered, aligned | Cross freely |
| **Dormant** | Powered down | Needs a Probe/Hack channel to wake; then open for the session |
| **Infected** | gROT has seeded it | Crossing applies Infection stacks (cap 5, existing system); Cybernex can cleanse it with Firewall |
| **Contested** | Both sides pulsing | The existing occupy-to-hold meter, reused verbatim |

This reuses systems the audit just repaired — `InfectionStatus`, `ChannelController`,
`PadBaseController`'s occupy-to-hold — instead of inventing parallel ones.

### 6.3 Ownership and stakes

A gate uses `OwnershipData` like a pad. The owning faction gets a **soft** benefit
only: faster traversal spool and a readout of recent traffic. Never a toll, never
a hard block on the other faction — a gate you cannot use at all would be a
hard-power lock, which the balance rules forbid.

### 6.4 Traversal

Fly into the ring at under 100 m/s → 2 s spool → arrive at the paired gate in the
destination system, moving. **No loading screen if it can be avoided:** the target
system's star, bodies and pads stream in during the spool, which is the same
staggered-build pattern `PlanetBody` already uses.

**DoD:** cross ARK → Helios Reach through a gate and back; wake a dormant gate with
Probe; an infected gate applies stacks and Firewall clears it; contested state uses
the existing meter.

---

## 7. Galaxy map and navigation

### 7.1 The map

`M` opens a 3D galaxy map. It is a **Control + Camera3D over a data set**, not a
loaded galaxy — no streaming, no memory cost beyond the node list.

- Systems as nodes, coloured by faction control, sized by economy.
- Links drawn for gate pairs (solid) and for in-range hyperspace hops (dashed).
- Undiscovered systems show as a dim unknown marker with no detail.
- Your current system is haloed; the plotted route is highlighted.
- Filters: faction, security, services (pad / refuel / arena / market), unexplored.

### 7.2 Route plotting

- Click a system → the map plots the cheapest legal route: gates preferred where
  they exist, hyperspace hops otherwise, respecting current range and fuel.
- The route panel lists each leg with its cost, and — critically — **names the
  reason a leg is impossible** rather than silently omitting it: `no gate, and
  14.2 ly exceeds 8 ly range`. The land-gate lesson generalises.
- Multi-leg routes persist in `NavState`; arriving advances the leg.

### 7.3 In-flight navigation

- A compass strip on the ship HUD: current system, next waypoint, distance,
  align cone when a jump is targeted.
- The existing `land_readiness_line()` pattern extends to a
  `jump_readiness_line()`: `JUMP: align 34°→15° · fuel 2.8→4.2`.
- The system map (`N`) is the local view: star, orbits, bodies, stations, gates,
  and your position — the thing you actually use to pick a destination in-system.

### 7.4 Knowledge, kept soft

Knowledge Rank may unlock **information**: hazard flags on a route, a better
traffic readout, an estimate of gate state before arrival. It never changes range,
charge time, fuel burn or gate access. This is the same line the audit had to
restore when Knowledge was found multiplying weapon damage.

**DoD:** open the map, plot a 3-leg route mixing a gate and a hyperspace hop, fly
it, and have the route advance as you arrive. Every rejected leg states why.

---

## 8. Arena entry from OpenSpace

Today `M`/`Tab` hard-cuts `OpenSpace` → `TestArena`. There is no in-world reason
for it, and the keybind is now wanted for the map.

### 8.1 Target

**Clash Beacons** are objects in the system — a station ring in orbit, or a
surface arena near a pad. Approach one, get a prompt, and enter.

1. Fly within 300 m of a Clash Beacon. The HUD offers `ENTER CLASH — hold F`.
2. Holding F for 1.2 s (no accidental transitions) plays a dock animation and
   swaps to the arena. `LayerContext` records the system, beacon and the
   player's ship state, exactly what `TransitionContext` (rules/18) exists for.
3. The arena runs as it does now, with the match-result panel the audit added.
4. Exiting returns you to **the same system, docked at the same beacon**, ship and
   cargo intact — not to a fresh scene.
5. Soft influence from the match lands on that system's pads through
   `apply_arena_influence`, the capped decaying path the audit installed. A match
   fought at an ARK beacon nudges ARK, which finally makes the arena's world
   connection legible.

### 8.2 Keys

- `M` → galaxy map (new)
- `N` → system map (new)
- `F` at a beacon → enter Clash (hold)
- `Tab` → keep as the developer shortcut, F3-gated

**DoD:** fly to a beacon in ARK, hold F, play a Clash match, return to the same
beacon still in ARK with the ship where you left it, and see the influence on an
ARK pad.

---

## 9. Rules compliance

| Rule | How this design holds it |
|------|--------------------------|
| No pay-to-win | Hyperdrive classes are earned; faction variants are mirrored at equal budget; no purchasable range, fuel or gate access |
| Soft Knowledge | Navigation Knowledge grants information only — never range, charge, fuel or access |
| No permadeath | Out of fuel is a tow, not a loss; a misjump damages the drive and displaces you |
| Infection cap 5 | Infected gates use the existing `InfectionStatus`, which hard-caps at 5 |
| Arena influence temporary | Beacon matches feed `apply_arena_influence` — capped, decaying, never a flip |
| rules/25 performance | One system resident at a time; the galaxy is data; gate traversal streams with the existing staggered builder; pads unload on departure (already measured flat) |
| Honest gates over hidden ones | Every refusal names the failing term, following the land gate |

---

## 10. Phasing

Each phase is independently playable, in the project's vertical-slice tradition.

### G0 — System layout **DONE**
Star, orbits, inclinations, belt from data; per-body light direction; gate anchors
authored. Measured: bodies at 3800 / 7400 / 11800, smoke green.

### G1 — CRUISE
`_flight_mode` gains CRUISE; mass lock; warp visuals; fuel trickle; HUD tier
readout. Raise orbits to the target scale in the same pass, since CRUISE is what
makes the larger scale playable.
*Touches:* `ShipController`, `ShipFlightModel`, `StarSystemCatalog`, `GameHUD`.

### G2 — Galaxy data + maps
`GalaxyCatalog`, `NavState`, the galaxy map (`M`) and system map (`N`), route
plotting with reasons. No travel yet — the maps are honest about what you cannot
reach.
*Touches:* new `scripts/galaxy/`, `scripts/ui/GalaxyMap.gd`, `LayerContext`.

### G3 — Hyperdrive + jumps
The module, the six-state sequence, fuel, refuel at pads, denial messages,
arrival star-adjacent, cooldown. Two systems is enough to prove it.
*Touches:* `ShipModule`, `ShipController`, new `HyperdriveController`, `NavState`,
`OpenSpace` (system load/unload).

### G4 — Gates
Gate prop and prefab, the four states, traversal with streaming spool, ownership
via `OwnershipData`, Probe to wake, Infection on infected gates.
*Touches:* new `scripts/world/HyperGate.gd`, `StarSystemCatalog`, `OwnershipData`,
`InfectionStatus`.

### G5 — Arena from the map
Clash Beacons in-world, hold-F entry, return to the same beacon, influence on the
host system.
*Touches:* new `scripts/world/ClashBeacon.gd`, `LayerContext`, `TestArena`,
`OpenSpace`.

### G6 — Content and polish
More systems from the lore seed, gate networks per faction, interdiction hooks,
fuel scooping, distress tow, map filters and search.

---

## 11. Risks

| Risk | Mitigation |
|------|-----------|
| CRUISE makes the system feel empty | Mass lock forces real approaches; belt, stations and gates give the outer system a reason to exist |
| Two travel systems overlap confusingly | Different jobs: gates are fixed, free and contestable; hyperspace is free-form and costs fuel. The map labels each leg by which one it uses |
| System load on gate traversal hitches | Reuse the staggered `PlanetBody` builder; spool time is the streaming budget; pads already unload on departure |
| Galaxy map becomes a spreadsheet | Political colour first, numbers on demand; filters instead of columns |
| Scope creep | Phases G1–G5 each ship playable; G6 is explicitly optional content |
| Fuel becomes a chore | Generous CRUISE burn, free refuel at friendly pads, and a tow that cannot strand you |

---

## 12. Asset requirements

Every mesh this plan needs is listed with its faction variants, LODs and priority
in **`docs/design/TRIPO_ASSET_MANIFEST.md`**.

---

*Design authority for the galaxy layer. Update this file in the same commit as
any change to travel, maps or system layout.*
