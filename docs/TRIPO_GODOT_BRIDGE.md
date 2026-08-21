# Tripo DCC Bridge for Godot (installed)

**Plugin:** Tripo Bridge 1.0.0  
**Path:** `godot/addons/Tripo3d_Godot_Bridge` → symlink → `~/Documents/naeon/Tripo3d_Godot_Bridge`  
**Port:** `ws://127.0.0.1:60650` (Blender bridge uses **60600** — no conflict)

## What it does

Receive models **directly from Tripo Studio into the Godot editor** (GLB/GLTF/FBX/OBJ/ZIP), auto-import + place in scene tree.

| Tool | Port | Target |
|------|------|--------|
| Blender Bridge | 60600 | Blender viewport |
| **Godot Bridge** | **60650** | Godot editor (this project) |
| API pipeline | — | `pipeline/inbox` → dual-theme LODs → assets/ |

## Use
1. Open **Godot 4.7.2** project `~/Documents/naeon/godot`
2. Dock **Tripo Bridge** (right) — server auto-starts
3. Tripo Studio → connect Godot DCC Bridge
4. Generate → model lands in project FS + scene

## Notes
- Editor-only plugin (`@tool`); not needed at runtime in exported game
- After import, still run NAEON dual-theme process if shipping faction variants
- Enable/disable: Project → Project Settings → Plugins → **Tripo Bridge**
