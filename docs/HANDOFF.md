# NAEON Handoff — Holistic Economical

**2026-08-06** | Credits **940** | Assets **32** | Installer **0.2.3** (~276MB with wear variants)

## Latest (this continue)
- `process_asset.py`: `--keep-materials` + `--wear` + collision in manifest
- sci_fi_crate reprocessed (clean/worn × factions × LOD)
- Ship hardpoints polish + **C** cargo module + detach_module
- Desktop: **NAEON-0.2.3-Installer.dmg**

## Play
Desktop → **NAEON-0.2.3-Installer.dmg**
or `cd ~/Documents/naeon/godot && godot .`

Space: Q fire | E land | R extractor | **C cargo** | Tab arena

## Free reprocess
```bash
python3 pipeline/scripts/process_asset.py \\
  --input pipeline/inbox/NAME/model.glb --name NAME --category CAT \\
  --keep-materials --wear
```

## Next
- Finish background PBR reprocess of hull/forms
- gh auth push
- Optional batch5 only for real content gaps
