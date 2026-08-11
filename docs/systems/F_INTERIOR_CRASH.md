# F interior crash + planet approach lag (2026-08-11T21:05:41.228726+00:00)

## Crash
F in interior → seat_to_pilot freed walker mid-notification → Object::has_method SIGSEGV.

Fix: mark_dying + deferred free next idle frame; seat/board use call_deferred finish.

## Lag 10–15s near planet
SurfaceDetail activated full ring + pad build + GLB + bases same frames.

Fix:
- Soft-start detail: ring 0→1→full over ~2.5s, budget 1, queue cap 12
- Stagger pads 1/frame
- Defer GLB + base stream
- Lower DEFAULT_RES 8, LOAD_BUDGET 1
