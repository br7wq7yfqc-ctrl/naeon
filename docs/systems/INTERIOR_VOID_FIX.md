# Interior void fall fix (2026-08-11T20:33:45.060336+00:00)

## Cause
1. F exit scheduled deferred `snap_to_surface` (0.05/0.15s)
2. I enter teleports to pocket at y=50000 under WorldRoot
3. Deferred snap still fires → raycast misses / FloatingOrigin rebases → void

## Fix
- Pocket parented under **OpenSpace** (not WorldRoot); fixed local (0,120,0)
- FloatingOrigin paused while inside
- `interior_mode` on SurfaceWalker blocks snap/safe_unground
- Guarded settle ticks abort if interior
- Thicker floors + under-slab + settle ray
- Void rescue if y drops below pocket
