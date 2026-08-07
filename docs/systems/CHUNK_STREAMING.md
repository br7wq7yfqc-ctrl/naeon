# Surface Chunk Streaming

## Goals
- No swimming (grid-locked lat/lon cells)
- Amortized cost (load budget / tick)
- Hysteresis unload (no thrash at cell borders)
- Mesh + node pools (no alloc storms)
- Quality tiers scale ring/res

## SurfaceDetail
| Param | Low | Med | High/Ultra |
|-------|-----|-----|------------|
| load ring | 1 (3×3=9) | 1 | 2 (5×5=25) |
| unload ring | 2 | 2 | 3 |
| res | 8 | 10 | 12–14 |
| budget | 2 meshes / 0.2s | same | same |
| mesh cache | 48 | 48 | 48 |

## Flow
1. Observer → cell
2. Enqueue missing cells in load ring (center first)
3. Build ≤ LOAD_BUDGET per stream tick
4. Recycle cells outside unload ring to pool
5. Periodic xform refresh (FloatingOrigin)

## Shared
`SurfaceChunkMath.gd` — cell_of, ring_cells, cell_transform, stable_tangent

Updated: 2026-08-07T23:11:23.130369+00:00
