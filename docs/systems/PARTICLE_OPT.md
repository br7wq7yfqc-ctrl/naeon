# Particle optimization (2026-08-08T16:06:26.845984+00:00)

## Changes
- `neon_particle.gdshader` — unshaded additive soft disc (no lighting, discard edge)
- Shared `QuadMesh` draw pass (2 tris) instead of SphereMesh
- Global oneshot budget by GraphicsQuality (4/8/12)
- Amount scale 0.45 / 0.7 / 1.0 by tier
- fixed_fps 24–30, no shadows, no GI, tight visibility_aabb
- Ship thruster: no per-frame `amount` realloc; cap 8–20
- CombatJuice / claim route through NeonParticles budget

Min-spec: RTX 1060 3GB target.
