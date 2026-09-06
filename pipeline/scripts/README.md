# Pipeline Scripts

## generate_tripo.py

Skeleton for Tripo generation.  
Requires `TRIPO_API_KEY` environment variable.

```bash
export TRIPO_API_KEY="tsk_..."
python generate_tripo.py --prompt "..." --name asset_name --priority B
python generate_tripo.py --image path/to/approved.jpg --name asset_name --priority B
```

Locked dual-theme plates: `--image` on the approved dump (crop the subject; do not mint a new UUID). Then:

```bash
python process_asset.py --input pipeline/inbox/NAME/model.glb --name NAME \
  --category props --keep-materials --no-tint --faction cybernex
```

## Coming next

- `process_asset.py` – Blender headless (LOD + Cybernex/gROT variants)
- `make_faction_variants.py`
- `run_pipeline.sh` – full orchestration
- Watcher for `inbox/`

All scripts must read secrets only from environment variables.
