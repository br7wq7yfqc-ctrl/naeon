# Controls · Surface walk · Character animation

## Issues addressed (2026-08-06)
1. **Flight plane only yaw** → ship body now pitches+yaws; thrust follows nose (SC-like). Z/X roll.
2. **Exit fall-through** → SurfaceWalker + radial gravity + raycast snap; no flat PlayerController on planet.
3. **No character anim** → procedural bob/lean/breathe/stomp on Visual; HQ form GLB attached.

## Ship (OpenSpace)
| Input | Action |
|-------|--------|
| Mouse | Flight plane (yaw + pitch of **hull**) |
| WASD | Thrust / strafe |
| Space/Shift | Lift / sink |
| Z / X | Roll |
| 1/2/3 | SCM / NAV / HOVER |
| E | Land / launch |
| F | Exit / enter |
| C | Claim pad (landed) / cargo module (flight) |

## On foot
| Input | Action |
|-------|--------|
| WASD | Move on **planet-tangent plane** |
| Mouse | Look (yaw around planet up, pitch cam) |
| Shift | Sprint |
| Space | Jump along radial up |
| F | Board ship |

## Animation roadmap
| Phase | What | Cost |
|-------|------|------|
| **Now** | Procedural bob/lean/idle | 0 |
| Next | Mixamo/retarget walk on form GLB if skinned | 0–low |
| Later | Tripo-rigged hero anim packs | Tripo credits |

## Plan checklist
- [x] 6DOF flight attitude
- [x] Surface snap + radial walk
- [x] Procedural character motion
- [ ] Blend tree when skeletal ready
- [ ] Ship landing gear anim
