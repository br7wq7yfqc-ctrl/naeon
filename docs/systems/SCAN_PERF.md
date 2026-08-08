# Scan performance (2026-08-08T00:54:40.994226+00:00)

## SoftScanCache
TTL: player 0.45s · pads 0.8s · planets 1.2s · terrain 0.7s · host file 2.5s

Consumers: GameHUD, PadBaseController, ShipController palette + SCAN mode.

## Ship SCAN
op_mode==2 → soft toast pulse 0.55s using nearest_pad/planet only. No combat.

## Landscape gen
PlanetRelief adds dune_amp, mesa_amp, crater_amp per planet profile.
SurfaceDetail mesh cache key `:v2` for biome colors.
