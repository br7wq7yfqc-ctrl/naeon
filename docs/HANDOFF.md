# Handoff — 0.3.14 perf / terrain swim fix

## Root causes (FPS + "terrain swimming")
1. **SurfaceDetail** used `Time.get_ticks_msec()` in patch angles → continuous orbit ("liquid" ground)
2. **PlanetTerrainEdit** re-anchored plate every 0.2s → plate followed player always
3. **SoftNetSession** DEFAULT ON: Dictionary snapshots @20Hz + LayerContextAuthority export + ghost mesh → GC/CPU in Arena AND OpenSpace
4. **GameHUD** FileAccess + get_nodes_in_group every frame
5. Terrain rebuild left old mesh/trimesh RID pressure

## Fixes
- SurfaceDetail: fixed angles, snap only after 18m move
- TerrainEdit: snap only after 14m, freeze while brushing; free old mesh; convex col
- SoftNetSession: default OFF; 4Hz light snaps when SoftENet on
- GameHUD / TestArena UI throttled
- Tripo Godot Bridge plugin disabled in project.godot (re-enable for DCC only)

## Sprint C next
Tripo skinned hero LODs after this stabilizes

## Budget
0 Tripo this fix pass

Updated: 2026-08-06T23:59:53.473502+00:00
