# Controls · Surface walk · Character animation

## Fix 2026-08-07 — sideways move + inverted mouse
**Root cause:**  built with  produced **left-handed** axes (det = −1).
That reflected strafe/look: WASD felt sideways, mouse X felt inverted, ships thrust off-nose.

**Fix:** right-handed construction , Godot columns .
Form/hull meshes rotated  so visual nose/face aligns with −Z thrust/walk.

## Ship (OpenSpace)
| Input | Action |
|-------|--------|
| Mouse | Look: right → yaw right, up → pitch up |
| WASD | Thrust forward / back / strafe |
| Space/Shift | Lift / sink |
| Z / X | Roll |
| 1/2/3 | SCM / NAV / HOVER |
| E | Land / launch |
| F | Exit / enter |

## On foot
| Input | Action |
|-------|--------|
| WASD | Move on planet-tangent plane (W = look direction) |
| Mouse | Look (yaw around planet up, pitch cam) |
| Shift | Sprint |
| Space | Jump along radial up |
| F | Board ship |
