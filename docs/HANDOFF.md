# Handoff — terrain dance fix

## Root cause
SurfaceDetail / TerrainEdit / Flora **followed the player** on a ring and rebuilt basis from observer each snap → continuous "swimming". LOD sphere mesh swaps also morphing.

## Fix
- Planet **lat/lon cell grid** anchors (stable across visits)
- Stable tangent basis (UP/RIGHT ref, no pole flips)
- LOD hysteresis ~0.5s before mesh swap
- No surface emission shimmer

Updated: 2026-08-07T23:03:47.555592+00:00
