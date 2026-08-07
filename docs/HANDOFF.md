# Handoff — 0.3.14 perf + Sprint C started

## FPS / memory root causes (fixed)
1. SurfaceDetail Time.get_ticks orbit → terrain "swimming"
2. SoftNetSession default ON @20Hz Dictionary alloc (Arena+OpenSpace)
3. GameHUD FileAccess + group scans every frame
4. Terrain plate re-anchor every 0.2s + trimesh RID churn

## Sprint C
- FormAnimator.gd: drive Skeleton3D bones if present
- HeroFormCatalog prefers *_skinned_* paths
- Tripo high wave: player_canine_skinned, grot_thrall, cybernex_sentry (running)
- Balance at start ~5130; 30 frozen on first task

## Installer
Desktop NAEON-0.3.14-Installer.dmg

Updated: 2026-08-07T00:05:20.809315+00:00
