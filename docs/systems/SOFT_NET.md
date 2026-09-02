# SoftNet (visual multiplayer only)

## Rules
- **No combat authority** — puppets visual-only
- **No P2W** — state is pose/form/faction/flight only
- is_instance_valid on all rebind/free paths
- **AR-F / AR-G:** `bind_visual_puppet` tags Clash bot slots (3v3 or 5v5). Host keeps combat. Do not `enable()` the 20Hz loop for those slots.
- **IN-F:** same tag on hangar viewer + rover / stored-ghost puppet. Host keeps rover drive. Not a netcode cluster.
- **MC-A:** same tag on ship-pocket viewer + crew-seat puppet. Host keeps hull / combat. No second physical hull. No passenger combat.
- **SN-A:** same tag on occupied-pad viewer + host `SurfaceWalker` puppet (optional PV-A rival pose). Host keeps Pulse / occupy. No second physical walker. Not ENet cluster.
- **SN-B:** same tag on seated hull viewer + host hull / pilot puppet (or crew-seat pose) on OpenSpace. Host keeps Pulse / occupy / thrust. No second physical hull. Not ENet cluster.
- **SN-C:** same tag on ST-A Strategy overlay (key B) viewer + host pad / strategy actor puppet (habitat / extractor / modules pose). Host keeps Pulse / occupy / Hack. No second physical pad modules. Not ENet cluster.
- **SN-D:** same tag on Clash (`TestArena` / `ClashMatchDirector`) viewer + host arena / Clash pose puppet. Host keeps Pulse / Hack / form. No second physical Clash dummy. AR-H door stays. Not ENet cluster.
- **MC-B:** same puppet. Station role `gunner` is a SoftKnowledge / HUD label. Host keeps combat. No passenger DPS.
- **MC-C:** engineer puppet on the third seat. Station role `engineer` is a SoftKnowledge / HUD label. Host keeps combat. No passenger DPS.
- **PV-A:** same tag on the pad rival `CombatDummy` + optional viewer. Host keeps Pulse combat. Not Clash. G5 stays closed.
- **PV-B:** same tag / same rival. Seated hull Pulse is host-authority. SoftNet visual bind only. Not Clash. G5 stays closed.

## Continuum fields (UDP STATE)


## Stale
Peers silent > 8s → puppet queue_free

## Transports
- UDP JSON primary
- ENet multiplayer fallback (reduced fields)
- Loopback for single-machine ghost

Updated: 2026-09-02T22:00:00.000000+00:00
