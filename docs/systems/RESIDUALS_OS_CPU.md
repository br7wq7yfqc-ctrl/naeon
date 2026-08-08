# Residuals + multi-planet + OS FPS deep (2026-08-08T23:34:23.511912+00:00)

## Facing
- SurfaceWalker uses SurfaceFacing.compute_wish (selftest parity)
- last_move_input for HUD

## Land
- Pad land now sets _land_lock_t=0.85 (was missing → sky climb)
- Softer launch boost; surface stick holds altitude

## Seat
- is_near_seat 7.5 / ship pocket 12
- SeatLabel + SeatGlow markers

## Multi-planet CPU
- _park_far_planets: only nearest (+<4500) set_process
- SoftNet SNAP 0.4s, history 12, process off when disabled

## OS FPS deep
- Asteroid belt 4–14 tier, no collision
- SurfaceDetail park alt 120, cache 32
