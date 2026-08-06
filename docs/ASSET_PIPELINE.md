# NAEON Asset Pipeline (Tripo-first, low-cost)

## Goal

Generate and process 3D assets for NAEON with **minimal external spend**, using:

- **Tripo** as primary generator (best free-tier value + good topology)
- Meshy as secondary
- Rodin only for rare hero assets
- Heavy post-processing on our Yandex VM (Blender headless)
- Automatic Cybernex / gROT dual-theme variants

## Priority system

| Priority | Type of asset | Generator policy |
|----------|---------------|------------------|
| **A** | Hero characters, flagship ships, key buildings | Tripo → Meshy → (rarely) Rodin |
| **B** | Regular units, modules, props | Tripo free credits only |
| **C** | Mass / background / decorations | Procedural + variants from existing meshes |

## Recommended tools

| Role | Tool | Notes |
|------|------|-------|
| Primary generation | **Tripo** | Best free credits + clean topology for games |
| Secondary | Meshy | Strong textures, good fallback |
| Hero only | Rodin | High fidelity, expensive |
| Processing | Blender headless on VM | LOD, UV, dual materials, export |
| Storage | Yandex Object Storage `neon` | `dev/` folder |

## Pipeline flow

```
1. Brief / Prompt (with faction + style)
2. Generate via Tripo API (prefer free credits)
3. Download .glb → pipeline/inbox/
4. Blender headless:
   - Cleanup
   - LOD0/1/2
   - Dual materials (Cybernex + gROT)
   - Collision
5. Export to assets/{category}/{name}/
6. rclone sync → s3://neon/dev/
7. Update assets_manifest.json
```

## Faction variants (almost free)

From **one** base mesh we automatically produce:

- `*_cybernex.glb` + materials (clean, cyan/white/green, Venus Project style)
- `*_grot.glb` + materials (industrial, biomass, red-purple, organic overlays)
- Shared LODs

This is the main cost-saving technique.

## Environment variables (never commit)

```bash
TRIPO_API_KEY=tsk_...
TRIPO_API_ID=naeon-grok          # optional
YC_STORAGE_ACCESS_KEY=...
YC_STORAGE_SECRET_KEY=...
YC_STORAGE_BUCKET=neon
YC_STORAGE_ENDPOINT=https://storage.yandexcloud.net
```

## Directory structure on VM / local

```
pipeline/
├── inbox/                 # raw downloads from Tripo/Meshy
├── processing/            # temp Blender work
├── processed/             # final glTF + materials
├── briefs/                # JSON briefs
├── scripts/
│   ├── generate_via_tripo.py
│   ├── process_asset.py     # Blender
│   ├── make_faction_variants.py
│   └── run_pipeline.sh
└── logs/

assets/                       # final Godot-ready assets (synced)
```

## Current status

- Storage + sync scripts: ready
- Tripo-first policy: defined
- Blender processing scripts: to be added next
- Full VM bootstrap script: next step

## Rules

- Never commit API keys or `.env`
- Prefer free Tripo credits
- One good mesh → many variants
- Only Priority A may spend paid credits
