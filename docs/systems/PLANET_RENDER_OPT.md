# Planet rendering optimization

## Goals
Stable 60 fps orbit/approach on **RTX 1060 3GB** (LOW/MEDIUM), richer near-surface on 3060+.

## Techniques
| Technique | Effect |
|-----------|--------|
| **4 LOD bands** NEAR/MID/FAR/IMPOSTOR | Segment count 64→32→16→8 |
| **Shared SphereMesh cache** | No per-planet mesh rebuild |
| **No planet shadows / GI** | Huge saving on large spheres |
| **Vertex shading** on MID/FAR | Cheaper lighting |
| **Atmosphere distance cull + alpha fade** | Transparent overdraw cut |
| **Pad streaming** | Built only when approaching; 1 GLB pad |
| **Collision disable** when far | Broadphase win |
| **LOD update 8 Hz** | Not every frame |
| **Starfield MultiMesh** | 160 instances, 1 draw |

## Distance bands (× prop_lod_bias from GraphicsQuality)
- NEAR: `< 2.2 R`
- MID: `< 5 R`
- FAR: `< 10 R`
- IMPOSTOR: `≥ 10–18 R`

## Quality tiers (`planet_segments`)
LOW 48 · MEDIUM 64 · HIGH 96 · ULTRA 128 (near LOD only)

## HUD
`PLOD: NEAR|MID|FAR|IMPOSTOR` on OpenSpace HUD.
