# Pipeline Scripts

## generate_tripo.py

Skeleton for Tripo generation.  
Requires `TRIPO_API_KEY` environment variable.

```bash
export TRIPO_API_KEY="tsk_..."
python generate_tripo.py --prompt "..." --name asset_name --priority B
```

## Coming next

- `process_asset.py` – Blender headless (LOD + Cybernex/gROT variants)
- `make_faction_variants.py`
- `run_pipeline.sh` – full orchestration
- Watcher for `inbox/`

All scripts must read secrets only from environment variables.
