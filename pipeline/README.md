# NAEON Asset Pipeline

Tripo-first, free-tier focused 3D asset pipeline.

See full documentation: [`docs/ASSET_PIPELINE.md`](../docs/ASSET_PIPELINE.md)

## Quick start (on Asset VM)

```bash
export TRIPO_API_KEY="your_key_here"
cd pipeline/scripts
python generate_tripo.py --prompt "cybernex canine robot scout, dark neon" --name canine_scout --priority B
```

Then process the downloaded model with Blender scripts (to be installed on the VM).
