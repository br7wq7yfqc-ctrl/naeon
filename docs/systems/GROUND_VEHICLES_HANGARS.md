# Ground Vehicles · Hangars · Cargo Ramps

**Status:** IN-C V0+V1 + IN-D V2 + IN-E V3 + IN-F V4 visual built  
**Benchmarks:** SC (vehicle hangar + ramp) · NMS (exocraft) · economical code-first  
**No P2W:** vehicle tiers = role / soft logistics, not shop combat power  

---

## 1. Fantasy

Large multiplayer ships (carriers, haulers, assault landers) store **ground vehicles** in hangars / cargo holds.  
Players drive them out via **ramps** onto planet pads or battlefield.  
Small ships: no hangar (or 1 bike hardpoint later).

## 2. Vehicle classes (Phase 1)

| Class | Role | Capacity slots | Combat |
|-------|------|----------------|--------|
| **Rover** | surface explore / claim assist | 1 | soft soft turret |
| **APC** | squad transport (2–4 seats soft) | 2 | soft only |
| **Miner crawler** | harvest Contribution/Biomass | 2 | none |
| **AA buggy** | soft AA vs ships near pad | 1 | soft AA |
| **Bike** | fast scout | 0.5 | none |

Storage unit: **HangarSlot** (volume + mass budget on hull).

## 3. Ship hangar / cargo architecture

```
CapitalShip / Hauler
  CargoHold (volume m³, mass t)
    HangarBay[] (door + interior spawn)
      VehiclePad[] (parked VehicleInstance)
    CargoRamp (deployable geometry + drive path)
```

### CargoRamp

| State | Geometry | Collision |
|-------|----------|-----------|
| STOWED | flush with hull | closed |
| DEPLOYING | tween 0.8–1.5s | partial |
| DEPLOYED | angle ~25–35° to ground/pad | walk/drive mesh |
| BLOCKED | too far from surface / speed high | toast |

**Deploy rules:** ship landed OR hover < 8 m AGL OR docked; speed < 5; OpMode allows CARGO_OPEN / DOCK.

### HangarBay interior

- Procedural box bay (like ship interior) + vehicle ghosts  
- Multiplayer: authority parks vehicle; soft puppets for others  
- Ramp mouth = NavLink for future AI  

## 4. Vehicle runtime

`GroundVehicle` (CharacterBody3D or RigidBody3D):

- Surface-aligned gravity (reuse SurfaceWalker up)  
- WASD drive, mouse look / turret  
- Board/exit **F** (same hardened pattern as ship)  
- SoftNet: pos, yaw, occupied  

### Store / retrieve

| Action | Flow |
|--------|------|
| Store | Drive onto ramp → hold bay volume → despawn world → add to CargoHold inventory |
| Deploy | UI or bay console → spawn on ramp top → player can board |

## 5. Multiplayer notes

- Hangar ownership = ship authority peer  
- Vehicle physical only when deployed  
- Stored vehicles = data on ship soft state (id, health, cargo soft)  
- No vehicle pay-stat power; cosmetics / QoL freemium later  

## 6. Economical assets

| Need | Approach |
|------|----------|
| Rover body | 1× Tripo standard later OR procedural box chassis now |
| Ramp | code MeshInstance3D plates |
| Bay | InteriorGenerator room profile `hangar_bay` |
| Wheels | cylinders procedural |

**0 Tripo until rover drive loop playable.**

## 7. Sprint order (after EVA/MORPH/INT)

| Sprint | Scope |
|--------|-------|
| V0 | CargoHold + HangarBay data on the ST-D catalog carrier (**built**, IN-C) |
| V1 | CargoRamp deploy/stow + walk plates hangar_bay → pad (**built**, IN-C) |
| V2 | GroundVehicle rover drive on surface (**built**, IN-D) |
| V3 | Store/retrieve flow (**built**, IN-E) |
| V4 | SoftNet visual puppet (**built**, IN-F). No second seat — `GroundVehicle` only has the IN-D pilot |
| V5 | Optional Tripo rover A |

## 8. Acceptance

1. Hauler lands → ramp deploys → rover drives out  
2. Rover returns up ramp → stored in hold  
3. Ship takes off with vehicle inventory  
4. Second local viewer sees ramp + vehicle puppet (soft) — **built**, IN-F visual only  

## 9. Links

- SHIP_EVA_INTERIOR_MORPH.md (cargo OpMode, interiors)  
- SEAMLESS_OPENSPACE.md  
- ShipRoleProfile.make_hauler() capacity fields  

IN-C (V0+V1): `HangarBay.gd` + `CargoHold` + `CargoRamp` on `CatalogCarrier` (`cybernex_capital_carrier` …). Deploy when landed / hover < 8 m AGL / docked and speed < 5; else BLOCKED toast. Hatch from `hangar_bay` onto deployed plates (not MainMenu). No rover spawn. 0 Tripo.

ST-J: pad-side `PadHangarStub` via `BaseBuilder` after occupy on unnamed `Pad_North` / `Pad_Approach` / `Pad_Flank`. Hatch/LAND stay on the pad (same OpenSpace). Not ST-D `CarrierHangarQueue`. No rover. No `SITE_*`.

ST-K: same `PadHangarStub` grammar on the existing `PlayerOrbitalStation` cluster via `BaseBuilder.place_orbital_hangar_stub`. SoftKnowledge / HUD label only. Host authority. Hatch/LAND stay legal. ST-E dock+habitat and ST-G factory stay. Not ST-D `CarrierHangarQueue`. Not IN-F SoftNet V4. No rover. No `SITE_*`.

IN-D (V2): `GroundVehicle` rover on ramp top when plates are `DEPLOYED`. WASD drive, `F` board/exit (walker parked, not freed). Drive onto the unnamed pad deck. One rover. No SoftNet multi-seat. No `SITE_*`. 0 Tripo. Procedural chassis/wheels.

IN-E (V3): drive onto the deployed ramp mouth / `hangar_bay` volume → despawn world rover → `CargoHold` (`id` + `health`). Bay console or hangar interact retrieves onto ramp top when `DEPLOYED` and IN-C pose rules pass. Takeoff keeps inventory. No second world rover. No pay-stat power. No SoftNet multi-seat. No `SITE_*`. 0 Tripo.

IN-F (V4 visual): second local viewer on the host sees CargoRamp `DEPLOYED` plus a SoftNet visual rover puppet (or stored ghost after IN-E store). Host keeps rover authority. Puppet is not a second `GroundVehicle` and has no combat. No passenger seat — `GroundVehicle` only has the IN-D `pilot`. Not a netcode cluster. No `SITE_*`. 0 Tripo.
