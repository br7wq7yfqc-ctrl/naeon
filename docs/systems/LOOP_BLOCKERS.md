# Loop blockers pass (2026-08-08T17:16:38.950560+00:00)

## Land
- `_land_lock_t` 0.65s ignores launch input (was accidental lift)
- `_stick_to_pad` soft-lerp + hard ceiling (no climb every frame)
- Launch: pad-up * 8 + nose * 3

## Exit / embed
- Spawn pad_up * 6.5 + side * 8.5
- Snap clearance 2.55m + multi-frame unground
- Spawn grace kills downward dig

## Facing
- Character MeshOrient `for_ship=false`
- Visual no Y spin (body yaw owns facing)
