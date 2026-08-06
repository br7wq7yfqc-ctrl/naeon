# NAEON Handoff — Holistic Economical

**2026-08-06** | Credits **940** | Assets **32** | Installer **0.2.3**

## Latest
- `process_asset.py`: `--keep-materials` (Tripo PBR tint) + `--wear` (free ×2 variants) + collision box in manifest
- Smoke: `sci_fi_crate` → clean/worn × factions × LODs (0 Tripo credits)
- Ship hardpoints: engine/weapon/shield/extractor/cargo GLB slots
- **C** in SpaceTest: attach cargo pod; **R**: extractor
- Turrets + ownership dual-mesh (0.2.2)

## Play
Desktop: **NAEON-0.2.3-Installer.dmg**
`cd ~/Documents/naeon/godot && godot .`

## Process with PBR keep
```bash
python3 pipeline/scripts/process_asset.py \\
  --input pipeline/inbox/NAME/model.glb --name NAME --category props \\
  --keep-materials --wear
```

## Next
- Batch reprocess priority B assets with --keep-materials (free, Blender only)
- Turret friendly fire tuning
- gh auth push
