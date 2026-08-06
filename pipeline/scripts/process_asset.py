#!/usr/bin/env python3
"""
NAEON Blender processor (economical):
  - LOD0/1/2 decimation
  - dual-theme Cybernex / gROT materials
  - optional --keep-materials (preserve Tripo PBR, tint only)
  - optional --wear (extra worn/damaged material variants — free multiplication)
  - collision hull proxy in manifest
  - export to assets/{category}/{name}/
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROCESSED = ROOT / "pipeline" / "processed"
ASSETS = ROOT / "assets"
PROCESSED.mkdir(parents=True, exist_ok=True)
ASSETS.mkdir(parents=True, exist_ok=True)


def find_blender() -> str:
    env = os.getenv("BLENDER_BIN")
    if env and Path(env).exists():
        return env
    candidates = [
        "/Applications/Blender.app/Contents/MacOS/Blender",
        str(Path.home() / "Applications/Blender.app/Contents/MacOS/Blender"),
        "/usr/bin/blender",
        shutil.which("blender") or "",
    ]
    for c in candidates:
        if c and Path(c).exists():
            return c
    return ""


def run_inside_blender(
    input_path: Path,
    name: str,
    out_dir: Path,
    category: str = "props",
    keep_materials: bool = False,
    wear: bool = False,
) -> None:
    import bpy

    out_dir.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # Import
    bpy.ops.import_scene.gltf(filepath=str(input_path))

    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise RuntimeError("No mesh objects after import")

    # Join meshes
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    base = bpy.context.view_layer.objects.active
    base.name = f"{name}_base"

    # Normalize scale to ~1.5m height
    dims = base.dimensions
    max_dim = max(dims.x, dims.y, dims.z) or 1.0
    target = 1.5
    if max_dim > 0.001:
        s = target / max_dim
        base.scale = (s, s, s)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    # Store original material slots if keep
    orig_mats = list(base.data.materials) if base.data.materials else []

    def export_glb(path: Path) -> None:
        bpy.ops.object.select_all(action="DESELECT")
        for o in bpy.context.scene.objects:
            if o.type == "MESH":
                o.select_set(True)
        bpy.ops.export_scene.gltf(
            filepath=str(path),
            export_format="GLB",
            use_selection=True,
            export_apply=True,
        )

    def clear_mats(obj) -> None:
        obj.data.materials.clear()

    def apply_faction_material(obj, faction: str, worn: bool = False) -> None:
        if keep_materials and orig_mats:
            # Clone materials and tint emission/base toward faction
            clear_mats(obj)
            for src in orig_mats:
                if src is None:
                    continue
                mat = src.copy()
                mat.name = f"{name}_{faction}_{'worn_' if worn else ''}{src.name}"
                # Tint principled if present
                if mat.use_nodes and mat.node_tree:
                    for n in mat.node_tree.nodes:
                        if n.type == "BSDF_PRINCIPLED":
                            col = n.inputs.get("Base Color")
                            emis = n.inputs.get("Emission Color") or n.inputs.get("Emission")
                            if faction == "cybernex":
                                tint = (0.15, 0.75, 1.0, 1.0)
                            else:
                                tint = (0.95, 0.12, 0.42, 1.0)
                            if col:
                                c = list(col.default_value)
                                col.default_value = (
                                    c[0] * 0.55 + tint[0] * 0.45,
                                    c[1] * 0.55 + tint[1] * 0.45,
                                    c[2] * 0.55 + tint[2] * 0.45,
                                    1.0,
                                )
                            if emis:
                                try:
                                    emis.default_value = tint
                                except Exception:
                                    pass
                            rough = n.inputs.get("Roughness")
                            if worn and rough:
                                rough.default_value = min(1.0, float(rough.default_value) + 0.25)
                            metal = n.inputs.get("Metallic")
                            if worn and metal:
                                metal.default_value = max(0.0, float(metal.default_value) - 0.15)
                obj.data.materials.append(mat)
            return

        mat = bpy.data.materials.new(name=f"{name}_{faction}{'_worn' if worn else ''}")
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        nodes.clear()
        out = nodes.new("ShaderNodeOutputMaterial")
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
        if faction == "cybernex":
            base_c = (0.08, 0.14, 0.2, 1.0)
            emis = (0.15, 0.85, 1.0, 1.0)
            metal, rough = 0.7, 0.28
        else:
            base_c = (0.18, 0.05, 0.08, 1.0)
            emis = (0.95, 0.12, 0.42, 1.0)
            metal, rough = 0.45, 0.4
        if worn:
            rough = min(1.0, rough + 0.3)
            metal = max(0.1, metal - 0.2)
            base_c = (base_c[0] * 0.7, base_c[1] * 0.7, base_c[2] * 0.7, 1.0)
        bsdf.inputs["Base Color"].default_value = base_c
        bsdf.inputs["Metallic"].default_value = metal
        bsdf.inputs["Roughness"].default_value = rough
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emis
            bsdf.inputs["Emission Strength"].default_value = 0.6 if not worn else 0.25
        clear_mats(obj)
        obj.data.materials.append(mat)

    lod_map = [("lod0", 1.0), ("lod1", 0.45), ("lod2", 0.18)]
    variants = [("clean", False)]
    if wear:
        variants.append(("worn", True))

    exports: list[str] = []
    for faction in ("cybernex", "grot"):
        for vname, worn in variants:
            for lod_name, ratio in lod_map:
                bpy.ops.object.select_all(action="DESELECT")
                base.select_set(True)
                bpy.context.view_layer.objects.active = base
                bpy.ops.object.duplicate()
                obj = bpy.context.view_layer.objects.active
                suffix = f"{faction}_{vname}_{lod_name}" if wear else f"{faction}_{lod_name}"
                obj.name = f"{name}_{suffix}"
                if ratio < 0.999:
                    mod = obj.modifiers.new(name="Decimate", type="DECIMATE")
                    mod.ratio = ratio
                    bpy.ops.object.modifier_apply(modifier=mod.name)
                apply_faction_material(obj, faction, worn=worn)
                out_path = out_dir / f"{name}_{suffix}.glb"
                export_glb(out_path)
                exports.append(str(out_path))
                # remove duplicate mesh to keep scene clean
                bpy.data.objects.remove(obj, do_unlink=True)

    # Simple collision: box dimensions of base
    d = base.dimensions
    collision = {
        "type": "box",
        "size": [round(float(d.x), 3), round(float(d.y), 3), round(float(d.z), 3)],
    }

    manifest = {
        "name": name,
        "category": category,
        "source": str(input_path),
        "exports": exports,
        "factions": ["cybernex", "grot"],
        "lods": ["lod0", "lod1", "lod2"],
        "keep_materials": keep_materials,
        "wear": wear,
        "collision": collision,
        "created": time.time(),
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps(manifest, indent=2))


def copy_to_assets(name: str, out_dir: Path, category: str = "props") -> None:
    dest = ASSETS / category / name
    dest.mkdir(parents=True, exist_ok=True)
    for f in out_dir.glob("*.glb"):
        shutil.copy2(f, dest / f.name)
    if (out_dir / "manifest.json").exists():
        shutil.copy2(out_dir / "manifest.json", dest / "manifest.json")
    print(f"✓ Copied to {dest}")


def main(argv: list[str] | None = None) -> int:
    if argv is None:
        if "--" in sys.argv:
            argv = sys.argv[sys.argv.index("--") + 1 :]
        else:
            argv = sys.argv[1:]

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--no-assets-copy", action="store_true")
    parser.add_argument("--category", default="props")
    parser.add_argument("--keep-materials", action="store_true", help="Preserve Tripo PBR, tint by faction")
    parser.add_argument("--wear", action="store_true", help="Also export worn material variants (free ×2)")
    args = parser.parse_args(argv)

    input_path = Path(args.input).resolve()
    if not input_path.is_file():
        print(f"ERROR: input not found: {input_path}")
        return 1

    out_dir = PROCESSED / args.name

    try:
        import bpy  # noqa: F401

        run_inside_blender(
            input_path,
            args.name,
            out_dir,
            getattr(args, "category", "props"),
            keep_materials=args.keep_materials,
            wear=args.wear,
        )
        if not args.no_assets_copy:
            copy_to_assets(args.name, out_dir, getattr(args, "category", "props"))
        return 0
    except ImportError:
        pass

    blender = find_blender()
    if not blender:
        print("ERROR: Blender not found. Install or set BLENDER_BIN.")
        return 1

    cmd = [
        blender, "--background", "--python", str(Path(__file__).resolve()), "--",
        "--input", str(input_path),
        "--name", args.name,
        "--category", args.category,
    ]
    if args.no_assets_copy:
        cmd.append("--no-assets-copy")
    if args.keep_materials:
        cmd.append("--keep-materials")
    if args.wear:
        cmd.append("--wear")
    print("→", " ".join(cmd))
    env = os.environ.copy()
    if sys.platform.startswith("linux") and not os.getenv("DISPLAY"):
        if shutil.which("xvfb-run"):
            cmd = ["xvfb-run", "-a"] + cmd
    return subprocess.run(cmd, env=env).returncode


if __name__ == "__main__":
    sys.exit(main())
