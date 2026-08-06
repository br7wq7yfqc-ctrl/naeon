# Tripo DCC Bridge for Blender (installed)

**Addon:** `Tripo3d_Blender_Bridge` v1.0.21  
**Blender:** 4.5 LTS  
**Install path:** `~/Library/Application Support/Blender/4.5/scripts/addons/Tripo3d_Blender_Bridge`  
→ symlink → `~/Documents/naeon/Tripo3d_Blender_Bridge/`

## What it does

This is **not** the same as our Python API pipeline (`generate_tripo.py`).

| | **DCC Bridge** | **API pipeline (NAEON)** |
|--|----------------|---------------------------|
| Trigger | [Tripo Studio](https://studio.tripo3d.ai) in browser | CLI / batch scripts |
| Transport | WebSocket **localhost:60600** Studio → Blender | REST OpenAPI → `pipeline/inbox/` |
| Credits | Studio plan / web balance | API key balance (`TRIPO_API_KEY`) |
| Result | Model appears **live in Blender scene** | GLB on disk → `process_asset.py` dual-theme LODs |
| Best for | Interactive sculpt/inspect, one-off hero art | Batch HQ regen, Godot-ready assets, dual-faction |

### Flow
1. Open Blender → sidebar **Tripo** tab → status **Waiting for connection** / **Connected**
2. Open Tripo Studio → connect DCC Bridge to Blender
3. Generate in Studio → mesh (GLB/etc.) auto-imports into the viewport
4. Then run NAEON `process_asset.py --keep-materials` if shipping into game

### Port
Bridge listens on **127.0.0.1:60600** (WebSocket). Firewall must allow local loopback (default).

## Enable / disable
Preferences → Add-ons → search **Tripo Bridge**  
Or:
```bash
Blender --background --python-expr 'import bpy; bpy.ops.preferences.addon_enable(module="Tripo3d_Blender_Bridge"); bpy.ops.wm.save_userpref()'
```

## Relation to HQ campaign
- Keep using **API wave scripts** for mass Godot assets (Wave S/A/C).
- Use **Bridge** when you want to refine a single hero mesh in Blender after Studio generation, or pull Studio results without downloading manually.
