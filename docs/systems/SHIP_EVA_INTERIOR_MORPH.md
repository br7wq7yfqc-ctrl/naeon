# Ship EVA · Interiors · Morph / Operational Modes

**Status:** Planned · Phase 0→1 continuum  
**Benchmark feel:** SC (EVA + seat) · NMS (cockpit) · EVE (mode-shift fantasy) — not feature clones  
**Economical rule:** code + procedural first; Tripo only for A-tier hero hull morph LODs later  
**No P2W:** siege/mode bonuses are hull **role identity**, never shop power  

---

## 0. Current truth (code tip)

| System | Now | Gap |
|--------|-----|-----|
| Exit ship **F** | Only when landed → SurfaceWalker on pad | No **open-space EVA** |
| Enter ship **F** | Near ship, free walker | No seat/cockpit state machine |
| Interior **I** | Procedural pocket rooms | Not tied to hull class; single-seater = generic 3 rooms |
| Flight modes | SCM / NAV / HOVER | No **role OpModes** (Siege / Scan / Cargo) |
| Geometry | Landing gear only | No hull morph / hardpoint transform |
| SoftNet | pos + mode + landed | Need EVA + op_mode + morph_t |

---

## 1. Open-space EVA (exit without landing)

### Fantasy
Leave the seat mid-flight or near station → thruster-suit outside the hull → reboard hatch. Same OpenSpace scene; FloatingOrigin tracks EVA actor.

### States (OpenSpace authority)

```
PILOT  --F / eject-->  EVA_SPACE  --F near hatch-->  PILOT
  |                         |
  | E land                  | thruster pack
  v                         v
LANDED (surface walk)     reboard / rescue
```

### Rules

| Rule | Spec |
|------|------|
| Exit | Pilot active; **not** require landed. Soft block if ship speed > `eva_max_exit_speed` (default 40) + toast |
| Spawn | Hatch hardpoint (default ship local +X*3 + up*1) outside collision |
| Actor | SurfaceWalker **EVA profile**: gravity ~0.05, WASD thrusters, Space/Shift vertical, optional mag-boot |
| Ship while EVA | pilot_active=false; damp velocity; optional HOVER assist near pad |
| Reboard | Distance to hatch < 4m; **same hardened free path** as pad reboard (rebind SoftNet before free) |
| Soft danger | EVA timer HUD warning only in Phase 0 — no hard death |
| Suit | Existing form + emission visor tint (0 Tripo) |

### EVA controls

| Input | Action |
|-------|--------|
| WASD | Thruster plane |
| Space / Shift | +up / -up |
| Mouse | Look |
| F | Reboard if in range else toast |
| E | Mag-boot toggle if ray hits hull/pad < 2m |
| I | Interior only if inside hull volume or on pad |

### Sprint S-EVA tasks

1. **E0** `ActorMode { PILOT, SURFACE, EVA }`; F without landed gate; speed check  
2. **E1** `SurfaceWalker.set_eva_profile(true)`  
3. **E2** Ship `HatchPoint` Marker3D; spawn/reboard  
4. **E3** Near-hull outline when EVA  
5. **E4** SoftNet `actor_mode=eva`  
6. **E5** Hatch juice (procedural door + audio)  

**Done when:** F in deep space → float → F reboard, no SIGSEGV.

---

## 2. Ship interiors (including single-seat)

### Philosophy
Every flyable hull has an **interior graph**. Single-seat ≠ empty: **Cockpit** (seat + console) + **Airlock/hatch** + optional micro-cargo niche.

### Profiles (data-driven)

`ShipInteriorProfile` / catalog id:

| Hull class | Rooms (min) | Props (reuse GLB) |
|------------|-------------|-------------------|
| **Scout / single-seat** | Cockpit · Airlock | ship_cockpit_console, control_console |
| **Fighter** | Cockpit · corridor · magazine | ammo_crate |
| **Hauler** | Cockpit · Cargo · Airlock | barrels, crates |
| **Sniper / siege** | Cockpit · Gunnery blister · Airlock | holo, long console |
| **Station** | existing station graph | habitat modules |

### Flow

```
SURFACE or EVA --near ship + I--> SHIP_INTERIOR pocket
SHIP_INTERIOR --I at hatch--> exterior mode (SURFACE / EVA)
SHIP_INTERIOR seat + F --> PILOT (fast path, no exterior hop)
```

### Single-seat special

- Seat volume + **F** → direct PILOT  
- Phase 0: neon cockpit only (no exterior portal)  
- Siege morph can move interior gunnery rails (child of morph alpha)

### Sprint S-INT tasks

1. **I0** Catalog (`ShipInteriorProfiles.gd` scaffold)  
2. **I1** `InteriorGenerator.build_from_profile`  
3. **I2** ShipController → profile id via role  
4. **I3** Seat volume → PILOT  
5. **I4** Dual-theme prop paths  
6. **I5** Tripo A bridge only after playable  

**Done when:** scout I → cockpit props → seat F → fly.

---

## 3. Mutable geometry and operational modes

### Layers

| Layer | What | Cost | Phase |
|-------|------|------|-------|
| L0 Landing gear | legs + VFX; G / pad LAND gate | done | 0 |
| L1 Hardpoint pose | Node3D tweens (barrel, radiators, doors) | code | 0–1 |
| L2 LOD morph set | cruise vs siege mesh swap | 1 mesh + Blender free | 1 |
| L3 Skinned morph | blend shapes | Tripo A | later |

Default: **L1 procedural plates**; L2 only for flagship sniper later.

### OpMode (orthogonal to SCM/NAV/HOVER)

Flight modes = how you fly. **OpMode** = how the hull is configured:

| OpMode | Mobility | Weapons | Geometry |
|--------|----------|---------|----------|
| **CRUISE** | 100% | baseline | compact |
| **SIEGE** | thrust×0.35, turn×0.4 | main dps×1.6, spread×0.5, RoF down | barrel extend, radiators, outriggers |
| **SCAN** | thrust×0.7 | weapons −20% soft | dish deploy |
| **CARGO_OPEN** | thrust×0.5 | weapons soft-off | bay doors |
| **DOCK_CLAMP** | locked | — | clamps |

Siege example (sniper role kit — not shop power):

- enter 1.2s / exit 0.8s  
- input **4** or **B** toggle  
- allowed in flight; on pad = “emplaced” fantasy  

### Sprint S-MORPH tasks

1. **M0** `ShipRoleProfile` + OpMode on ship; HUD OP:  
2. **M1** Apply mults from profile  
3. **M2** `ShipHullMorph` tween plates  
4. **M3** Proxy plates if no hero mesh  
5. **M4** SoftNet op_mode + morph_t  
6. **M5** Optional Tripo sniper hull  

**Done when:** toggle Siege → visible morph + slower ship + harder main gun.

---

## 4. Unified continuum state machine

```
                 land E
 PILOT <--------------------> LANDED_PILOT
   | F eva/surface                 | F
   v                               v
 EVA_SPACE                    SURFACE_WALK
   | I hull                        | I pad/ship
   v                               v
 SHIP_INTERIOR <---- I ----> STATION_INTERIOR
   | seat F
   v
 PILOT
```

LayerContext persists: `actor_mode`, `op_mode`, `interior_id`.

---

## 5. SoftNet fields

| Field | Notes |
|-------|-------|
| actor_mode | pilot / surface / eva / interior |
| op_mode | cruise / siege / scan / cargo / dock |
| morph_t | 0–255 |
| landed | existing |

---

## 6. Economical / Tripo

| Need | Approach | Credits |
|------|----------|---------|
| EVA suit | tint form | 0 |
| Scout interior | procedural + existing console | 0 |
| Morph plates | code | 0 |
| Sniper hero hull | 1× high later | ~50–90 at gate |

**No Tripo** until S-EVA + S-MORPH playable.

---

## 7. Sprint order (locked)

| # | Sprint | Deliverable |
|---|--------|-------------|
| 1 | **S-EVA** | Mid-space F exit/reboard |
| 2 | **S-MORPH** | OpMode SIEGE + mults + plates |
| 3 | **S-INT** | Scout single-seat interior + seat→pilot |
| 4 | **S-NET** | Replicate new fields |
| 5 | **S-POLISH** | juice → batch **0.3.18** |

---

## 8. Acceptance

1. Mid-space F → EVA → F reboard, no crash  
2. Single-seat I → cockpit → seat F → flight  
3. Siege toggle → morph + mobility down + main dps up (HUD)  
4. Landed F still surface walk; claim intact  
5. No P2W  

## 9. Open questions (owner optional)

- EVA hard oxygen fail vs soft-only? **Default soft**  
- Siege in all flight modes vs NAV-only? **Default all except DOCK**  
- Multi-crew seats: **MC-A + MC-B + MC-C + MC-D built** (gunner + engineer + ops seats on the player hull pocket; labels only)  

---

Scaffold already on disk:

- `godot/scripts/ship/ShipRoleProfile.gd`
- `godot/scripts/ship/ShipHullMorph.gd`
- `godot/scripts/ship/ShipInteriorProfiles.gd`

*Authority doc for EVA / interiors / morph. Update status when sprints complete.*
