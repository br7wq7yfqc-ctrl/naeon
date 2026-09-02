# Seat → Pilot & EVA (2026-08-08T01:25:11.626302+00:00)

## Seat [F]
- Requires interior `is_inside` + near SeatVolume/Seat/Spawn
- `exit_for_pilot()` frees pocket without surface teleport
- Walker disabled then `queue_free` (no SIGSEGV path)
- Hatch door closed; pilot active
- I from pilot leaves the seat **into the pocket** (no exterior hop)
- I at airlock/hatch leaves to EVA (zero-G if not landed) or the pad. Doors lead to pocket or EVA — never a locked prop.

## Crew seat [F] (MC-A + MC-B)
- Same ship_int pocket. Nearer-seat wins: `CrewSeat` is not the pilot `Seat`.
- **F** boards (`try_board_legal_seat` role=`crew`). Walker stays. Occupied marker visible.
- **I** / **F** while seated returns to the same pocket (IN-B pattern). No exterior hop.
- HUD `CREW n/3` is a label only. Knowledge does not change thrust / DPS / yield.
- **MC-B:** station role `gunner` is a SoftKnowledge / HUD label (`GUNNER`). Does not change Pulse / Hack / DPS / thrust / yield or unlock exclusive modules. F/I role stays `crew`.
- **MC-C:** third legal seat `EngineerSeat` (`engineer_seat` offset). Station role `engineer` is a SoftKnowledge / HUD label (`ENGINEER`). HUD `CREW n/3`. Gunner seat stays. F/I role stays `crew`. Pilot F/I unchanged.
- **MC-D:** fourth legal seat `ScannerSeat` (`scanner_seat` offset). Station role `scanner` is a SoftKnowledge / HUD label (`SCANNER`). HUD `CREW n/4`. Gunner + engineer stay. F/I role stays `crew`. Pilot F/I unchanged.
- Optional SoftNet visual puppet when a second local viewer exists. Host authority. No second hull. No passenger combat.

## EVA
- Exit ship when not landed and spd ≤ 42
- Spawn at HatchPoint + side offset; door ajar
- Velocity match 0.9× ship
- Near-ship OpenSpace EVA is **zero-G** (no planet gravity). Landed F stays grounded SurfaceWalker
- Thrusters cost energy (~4.5/s when thrusting)
- Soft tether toast if >80m from ship
- Soft suit warn after 90s EVA time
- Reboard distance measured to HatchPoint (24m EVA)

No combat power from EVA. No P2W.
