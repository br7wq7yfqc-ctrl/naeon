# Ship EVA · Interiors · Morph / Operational Modes

**Status:** Planned · Phase 0→1 continuum  
**Benchmark feel:** SC (EVA + seat) · NMS (cockpit) · EVE (mode shift fantasy) · not feature-clone  
**Economical rule:** code + procedural first; Tripo only for A-tier hero hull morph LODs later  
**No P2W:** siege/mode bonuses are **hull role identity**, not monetized power  

Updated: 2026-08-07T10:55:29.115564+00:00

---

## 0. Current truth (code tip)

| System | Now | Gap |
|--------|-----|-----|
| Exit ship **F** | Only when  → SurfaceWalker on pad | No **open-space EVA** |
| Enter ship **F** | Near ship, free walker | No seat/cockpit state machine |
| Interior **I** | Pocket rooms (InteriorGenerator) on foot near pad/ship | Ship interior not tied to hull class; single-seater = same 3 rooms |
| Flight modes | SCM / NAV / HOVER | No **role modes** (Siege / Scan / Cargo) |
| Geometry | Landing gear deploy/stow only | No hull morph / hardpoint transform |
| SoftNet | pos + mode + landed | Must extend for EVA + op-mode + morph stage |

---

## 1. Open-space EVA (exit ship without landing)

### 1.1 Player fantasy
- In free flight or near station: leave seat → float outside hull → reboard hatch.
- Continuum **same scene** (no ). FloatingOrigin tracks EVA actor.

### 1.2 States (authority: OpenSpace)


### 1.3 Rules
| Rule | Spec |
|------|------|
| Exit condition |  and (**not** requiring land). Optional: ship speed <  (default 40 m/s) else confirm / soft block + toast |
| Spawn | Hatch hardpoint (default: ship local ) outside collision |
| Actor |  with ** / EVA profile**: low gravity blend, thruster WASD+Space/Shift, mag-boot when near hull/pad |
| Ship while EVA | ; hold velocity damp; optional soft autopilot HOVER if near pad |
| Reboard | Distance to hatch < 4 m **or** seat volume; same hardened free path as land reboard (unbind SoftNet → ship first) |
| Oxygen / soft danger | Soft only: HUD “EVA time” warning at long duration — **no hard death** in Phase 0; later Knowledge soft tip |
| Suit form | Current HeroFormCatalog form with EVA tint (emission visor) — 0 Tripo |

### 1.4 Controls (EVA)
| Input | Action |
|-------|--------|
| WASD | Local thruster plane (camera/body) |
| Space / Shift | +up / −up along suit up |
| Mouse | Look |
| F | Reboard if in range else toast “approach hatch” |
| E | Mag-boot toggle when ray hits ship/pad within 2 m |
| I | If inside ship hull volume → ship interior pocket; from EVA exterior → no station unless near pad |

### 1.5 Implementation order (EVA)
1. **E0** Data: ; remove hard  gate on F; speed check  
2. **E1**  — gravity scale 0.05, thruster accel, no floor snap  
3. **E2** Hatch Marker3D on Ship (); spawn/reboard use it  
4. **E3** Ship exterior soft “tether” outline when EVA near  
5. **E4** SoftNet:  + suit form  
6. **E5** Juice: hatch open anim (procedural door plate), air-hiss audio  

**Exit criterion E0–E2:** F in deep space → float → F reboard without crash.

---

## 2. Ship interiors (including single-seat)

### 2.1 Philosophy
Every flyable hull has an **interior graph**, even scout single-seaters.  
Single-seat ≠ empty: **Cockpit** (seat + console) + **Hatch airlock** + optional **micro-bunk/cargo niche**.

### 2.2 Interior profiles (data-driven)



| Hull class | Rooms (min) | Props (reuse assets) |
|------------|-------------|----------------------|
| **Scout / single-seat** | Cockpit · Airlock | ship_cockpit_console, control_console, hatch label |
| **Fighter** | Cockpit · Short corridor · Magazine | ammo_crate, console |
| **Hauler** | Cockpit · Cargo bay · Airlock | barrels, crates, fuel_tank LOD |
| **Sniper / siege** | Cockpit · Gunnery blister · Airlock | long console, holo_projector |
| **Station dock** | existing station graph | habitat modules |

### 2.3 Flow (unified)


### 2.4 Single-seat special cases
- **Sit/stand:** in cockpit seat area, **F** or **E** boards pilot without leaving pocket first (fast path).  
- **Look out:** optional exterior camera portal later; Phase 0 = neon cockpit only.  
- **Morph visible inside:** gunnery blister rails move when Siege engages (see §3) — interior child bones/meshes follow morph alpha.

### 2.5 Implementation order (Interiors)
1. **I0**  Resource + JSON/catalog for scout default  
2. **I1**  — replace hard-coded only rooms  
3. **I2** Wire ship class on ShipController → profile id  
4. **I3** Seat volume → direct PILOT  
5. **I4** Dual-theme prop paths (existing  / )  
6. **I5** Tripo A only for hero bridge modules when budget allows (not required for playable)

**Exit criterion I0–I3:** single-seat scout has cockpit+airlock; I enter; F sit → fly.

---

## 3. Mutable ship geometry & operational modes

### 3.1 Layers of “shape change”

| Layer | What moves | Cost | Phase |
|-------|------------|------|-------|
| **L0 Landing gear** | Legs + thruster VFX | done | 0 |
| **L1 Hardpoint pose** | Turrets/wings/radiators rotate/slide via Node3D tweens | code | 0–1 |
| **L2 LOD morph set** | Swap or blend hull visual A/B (cruise vs siege mesh) | 1 base + Blender variants free | 1 |
| **L3 Skinned morph** | Blend shapes / skeleton on hero hull | Tripo A + pipeline | later |

**Economical default:** L1 procedural plates + module offsets; L2 only for flagship sniper when credits allow **one** high mesh → dual pose in Blender.

### 3.2 Operational modes (beyond SCM/NAV/HOVER)

Flight envelope (existing) stays **how you fly**.  
Operational modes = **how the hull is configured** (orthogonal):



| OpMode | Mobility | Weapon | Geometry signal | Unlock / role |
|--------|----------|--------|-----------------|---------------|
| **CRUISE** | 100% thrust/turn | baseline | wings swept / gear up | default all hulls |
| **SIEGE** | thrust ×0.35, turn ×0.4, damp ↑ | main gun dps ×1.6, spread ↓, fire rate ↓ | radiators deploy, barrel extend, outriggers | sniper / gunnery hulls |
| **SCAN** | thrust ×0.7 | weapons −20% soft | dish deploy | scout / science |
| **CARGO_OPEN** | thrust ×0.5 | weapons disabled soft | bay doors | hauler |
| **DOCK_CLAMP** | locked | — | clamps | near pad/station auto |

**Soft-only rule:** numbers are **role kits** on hull definition, not shop power. Knowledge can show *how* to use Siege (soft), not +dps.

### 3.3 Siege mode detail (sniper example)



**Input:** hold **B** or **4** toggle Siege (toast + morph tween). Cannot Siege while HOVER-landed? → allowed on surface as “emplaced” fantasy (even lower move).

### 3.4 Implementation order (Morph / OpMode)
1. **M0**  +  on ShipController; HUD shows OP:CRUISE/SIEGE  
2. **M1** Apply mobility/weapon multipliers from profile (data only)  
3. **M2**  — tween listed Node3D toward siege poses (procedural plates if missing)  
4. **M3** Auto-create proxy morph plates on scout if no mesh (visible non-placeholder cubes/plates)  
5. **M4** SoftNet:  +  0..1  
6. **M5** Optional Tripo: one sniper hull A-tier → Blender cruise/siege variants  

**Exit criterion M0–M3:** toggle Siege → ship slows, gun hits harder, visible geometry change.

---

## 4. Unified state machine (OpenSpace)



Persist on LayerContext: , , .

---

## 5. SoftNet / multiplayer soft

| Field | Type | Notes |
|-------|------|-------|
| actor_mode | u8 | pilot/surface/eva/interior |
| op_mode | u8 | cruise/siege/… |
| morph_t | u8 | 0–255 |
| landed | bit | existing |

Puppets: show gear + morph pose + suit outside ship.

---

## 6. Economical / Tripo budget mapping

| Need | Approach | Credits |
|------|----------|---------|
| EVA suit | tint existing form | 0 |
| Scout interior | procedural + cockpit console asset | 0 |
| Morph plates | code boxes/plates | 0 |
| Siege sniper hero hull | 1× high/ultra later | ~50–90 when gate |
| Dual-theme morph | Blender free from one mesh | 0 |

**Do not** spend Tripo on interiors until M0–M3 and E0–E2 playable.

---

## 7. Sprint schedule (post-0.3.17 tip)

| Sprint | Scope | Deliverable | Est. |
|--------|-------|-------------|------|
| **S-EVA** | E0–E2 | F deep space EVA + reboard | 1 session |
| **S-INT** | I0–I3 | Scout profile cockpit+airlock+seat→pilot | 1 session |
| **S-MORPH** | M0–M3 | OpMode SIEGE + visible morph + DPS/mobility | 1 session |
| **S-NET** | E4 M4 | SoftNet fields | half session |
| **S-POLISH** | juice, HUD, audio | batch **0.3.18** candidate | gate |

Order: **S-EVA → S-MORPH (data) → S-INT → S-NET** so modes exist before interior seat binds.

---

## 8. Acceptance (playable, not placeholder)

1. Mid-space: F → EVA thrusters → F reboard, no SIGSEGV.  
2. Single-seat: I → cockpit props → seat F → flight.  
3. Siege: 4/B → morph deploys, speed drops, main gun hits harder (HUD shows mult).  
4. Landed F still surface walk; pad claim intact.  
5. No P2W / no shop power.

---

## 9. Open questions (owner optional)

- EVA oxygen hard fail or soft-only forever in freemium? (default soft)  
- Siege allowed while NAV only vs any flight mode? (default any except DOCK_CLAMP)  
- Multi-crew seats later — out of Phase 0 scope  

---

*This document is the authority for EVA / interiors / morph. Implementation agents must update status lines when sprints complete.*
