# Memory P0–P1 (sequential, no DMG)

1. SurfaceDetail POOL_MAX=8 — excess queue_free; park_all trims + drops mesh cache
2. Far planets: _park_all() unload live meshes (not hide-only)
3. NeonParticles shared ShaderMaterial cache (16 keys)
4. InteriorGenerator PackedScene cache for GLB (24)
5. CombatJuice / AbilityVfx shared flash/impact mats

No installer until commanded.
