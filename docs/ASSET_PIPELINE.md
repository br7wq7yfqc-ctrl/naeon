# NAEON Asset Pipeline (Tripo-first, minimal cost)

## Goal

Fully automated (as much as possible) generation and processing of 3D assets with **minimal external spend**.

**Maximum ready-made from the net. Generate (Tripo) only unique objects.**
Short anchor: `docs/design/ASSET_SOURCE_CANON.md`.  
Authority for the unique / generic split, source order, and licence table:
`docs/design/WORLD_FILL.md` §3.1. Do not spend Tripo on dirt or unnamed rocks.
Git holds `source` / `license` / `url` on the position — never GLB or textures.

Primary generation service (unique only): **Tripo**  
Secondary: Meshy (fallback)  
Rare: Rodin (hero assets only)

All heavy processing (LOD, dual-theme materials, export) happens on the Yandex Cloud VM + local `assets/` folder synced with bucket `neon`.

---

## Priority System

| Priority | Description | Generation source | Notes |
|----------|-------------|-------------------|-------|
| **A** | Hero characters, flagship ships, key buildings | Tripo (paid if needed) → Rodin only if critical | Highest quality |
| **B** | Regular units, modules, important props | Tripo free credits / Meshy free | Good enough + variants |
| **C** | Mass decoration, repeated elements | **Ready-made** (CC0 / paid scan) or procedural + Blender re-skin — not Tripo | WorldFill generic; see §3.1 |

---

## High-level Flow

```
1. Brief / Prompt (A/B/C priority)
2. Tripo generation (prefer free credits)
3. Download .glb → pipeline/inbox/
4. Blender headless processing
   - Cleanup
   - LOD0/1/2
   - Cybernex material variant
   - gROT material variant
   - Collision
5. Export to assets/{category}/{name}/
6. Update assets_manifest.json
7. rclone sync → s3://neon/dev/
```

---

## Folder Structure

```
naeon/
├── pipeline/
│   ├── inbox/              # raw downloads from Tripo/Meshy
│   ├── processing/         # temp Blender work
│   ├── processed/          # final godot-ready assets
│   ├── briefs/             # json briefs
│   └── scripts/
│       ├── generate_tripo.py
│       ├── process_asset.py
│       ├── make_faction_variants.py
│       └── run_pipeline.sh
├── assets/                 # local working copy (gitignored)
└── godot/
```

---

## Tripo Integration

- API key must be provided via environment variable:
  ```bash
  export TRIPO_API_KEY="tsk_..."
  ```
- Never commit the real key.
- Script `pipeline/scripts/generate_tripo.py` will:
  - Accept a prompt + priority
  - Call Tripo API
  - Poll for result
  - Download GLB into `pipeline/inbox/`

---

## Free-tier Strategy

1. Always exhaust Tripo free credits first — and only on **unique** A/B (WORLD_FILL §3.1).
2. Use Meshy free tier as second source.
3. Generate one good base mesh → create many variants in Blender (Cybernex / gROT + color / wear variations).
4. Only upgrade to paid when free limits are exhausted and the asset is Priority A.

---

## Dual Faction Variants (almost free)

After a base mesh is ready, Blender scripts automatically produce:

- `*_cybernex.glb` + materials (clean, cyan/white/green emission, Venus Project style)
- `*_grot.glb` + materials (dark, organic, red-purple, biomass overlays)

This is the main cost-saving mechanism of the pipeline.

---

## Current Status

- Documentation and structure defined
- Scripts to be expanded on the Asset Pipeline VM
- Local `assets/` + rclone sync already prepared
- Godot `AssetLoader` supports threaded loading

Next steps after VM setup:
1. Install Blender headless + dependencies
2. Implement `generate_tripo.py`
3. Implement `process_asset.py` (LOD + dual materials)
4. Connect watch → process → sync loop
