# NAEON Handoff — HQ Wave S in progress

**2026-08-06** | Installer 0.2.5 | Bridges Blender+Godot installed

## HQ campaign (20k plan)
- See `docs/pipeline/HQ_TRIPOPLAN_20K.md`
- Wave S daemon: `bash pipeline/scripts/run_hq_wave.sh S 150` (raise floor to 500 after top-up)
- Ultra cost observed: **50 cr/asset** (v3.1 detailed)
- Done so far (see `logs/hq_wave_S.log`): forms + hull + more as wave proceeds
- After S: `run_hq_wave.sh A 500` then C

## Bridges
- Blender Tripo Bridge: port **60600**, enabled in 4.5
- Godot Tripo Bridge: port **60650**, `godot/addons/Tripo3d_Godot_Bridge` enabled

## Gameplay
- Form meshes + ship hull + enemies prefer **lod0** HQ GLBs
- Arena key props lod1

## Next
1. Finish Wave S → A
2. Owner top-up to ~20k for C + retexture
3. Rebuild installer **0.3.0** with HQ assets
