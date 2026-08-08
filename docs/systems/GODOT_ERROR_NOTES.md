# Godot error triage (2026-08-08)

## Fixed
1. SoftScanCache / PadBase / TerrainEdit parse breaks (stripped quotes, indent)
2. SurfaceDetail/TerrainEdit no longer assign mesh=null
3. GlbProp / ship modules / hull / radiators skip glTF under headless dummy renderer
4. GPUParticles without draw_pass_1 get SphereMesh
5. MeshOrient skips empty meshes

## Residual under --headless only
ERROR Parameter "m" is null at mesh_get_surface_count (dummy mesh_storage)
- GDScript reports 0 MeshInstance with mesh==null
- Dummy renderer RID not registered for some Primitive/Array meshes when culled
- Does NOT appear as SCRIPT ERROR; does not block play
- Real macOS/Vulkan editor/player uses valid RIDs

## Verify
scripts/playtest_headless_smoke.sh → SCRIPT ERROR = 0
