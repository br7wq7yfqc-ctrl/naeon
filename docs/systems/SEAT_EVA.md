# Seat → Pilot & EVA (2026-08-08T01:25:11.626302+00:00)

## Seat [F]
- Requires interior `is_inside` + near SeatVolume/Seat/Spawn
- `exit_for_pilot()` frees pocket without surface teleport
- Walker disabled then `queue_free` (no SIGSEGV path)
- Hatch door closed; pilot active

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
