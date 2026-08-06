#!/usr/bin/env python3
"""
NAEON Blender headless processor:
  - import GLB
  - basic cleanup
  - export LOD0/1/2
  - dual-theme material variants (Cybernex / gROT)

Usage:
  blender --background --python process_asset.py -- --input path/to/model.glb --name canine_scout
  # or (auto-finds blender):
  python process_asset.py --input path/to/model.glb --name canine_scout
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

ROOT = Path(__file__).resolve().parents[1]
PROCESSED = ROOT / "processed"
ASSETS = Path(__file__).resolve().parents[2] / "assets"


def find_blender() -> str:
    for c in [
        os.getenv("BLENDER_BIN", ""),
        "blender",
        "/usr/local/bin/blender",
        "/opt/blender/blender",
        "/Applications/Blender.app/Contents/MacOS/Blender",
        str(Path.home() / "Applications" / "Blender.app" / "Contents" / "MacOS" / "Blender"),
    ]:
        if c and shutil.which(c):
            return shutil.which(c) or c
        if c and Path(c).is_file():
            return c
    return ""


def run_inside_blender(input_path: Path, name: str, out_dir: Path) -> None:
    import bpy  # type: ignore

    # Reset scene
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # Import
    ext = input_path.suffix.lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(input_path))
    elif ext == ".obj":
        bpy.ops.wm.obj_import(filepath=str(input_path))
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(input_path))
    else:
        raise RuntimeError(f"Unsupported format: {ext}")

    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise RuntimeError("No mesh objects after import")

    # Join meshes for simple LOD pipeline
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    base = bpy.context.view_layer.objects.active
    base.name = name

    # Center & normalize scale roughly
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    base.location = (0, 0, 0)
    max_dim = max(base.dimensions) if max(base.dimensions) > 0 else 1.0
    scale = 2.0 / max_dim
    base.scale = (scale, scale, scale)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    out_dir.mkdir(parents=True, exist_ok=True)

    def export_glb(path: Path) -> None:
        bpy.ops.export_scene.gltf(
            filepath=str(path),
            export_format="GLB",
            use_selection=True,
            export_apply=True,
        )

    def set_faction_material(obj, faction: str) -> None:
        mat = bpy.data.materials.new(name=f"{name}_{faction}")
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        nodes.clear()
        out = nodes.new("ShaderNodeOutputMaterial")
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        em = nodes.new("ShaderNodeEmission")
        mix = nodes.new("ShaderNodeMixShader")
        if faction == "cybernex":
            base_col = (0.05, 0.15, 0.22, 1)
            em_col = (0.15, 0.85, 1.0, 1)
            em.inputs["Strength"].default_value = 2.0
        else:
            base_col = (0.12, 0.03, 0.06, 1)
            em_col = (0.95, 0.12, 0.4, 1)
            em.inputs["Strength"].default_value = 2.2
        bsdf.inputs["Base Color"].default_value = base_col
        bsdf.inputs["Metallic"].default_value = 0.65
        bsdf.inputs["Roughness"].default_value = 0.3
        em.inputs["Color"].default_value = em_col
        links.new(bsdf.outputs["BSDF"], mix.inputs[1])
        links.new(em.outputs["Emission"], mix.inputs[2])
        mix.inputs["Fac"].default_value = 0.35
        links.new(mix.outputs["Shader"], out.inputs["Surface"])
        if obj.data.materials:
            obj.data.materials[0] = mat
        else:
            obj.data.materials.append(mat)

    # LOD ratios (decimate)
    lod_ratios = [("lod0", 1.0), ("lod1", 0.45), ("lod2", 0.18)]
    exports = []

    for faction in ("cybernex", "grot"):
        for lod_name, ratio in lod_ratios:
            # Duplicate base
            bpy.ops.object.select_all(action="DESELECT")
            base.select_set(True)
            bpy.context.view_layer.objects.active = base
            bpy.ops.object.duplicate()
            obj = bpy.context.view_layer.objects.active
            obj.name = f"{name}_{faction}_{lod_name}"
            if ratio < 1.0:
                mod = obj.modifiers.new(name="Decimate", type="DECIMATE")
                mod.ratio = ratio
                bpy.ops.object.modifier_apply(modifier=mod.name)
            set_faction_material(obj, faction)
            out_path = out_dir / f"{name}_{faction}_{lod_name}.glb"
            bpy.ops.object.select_all(action="DESELECT")
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            export_glb(out_path)
            exports.append(str(out_path))
            # cleanup duplicate
            bpy.data.objects.remove(obj, do_unlink=True)

    manifest = {
        "name": name,
        "source": str(input_path),
        "exports": exports,
        "factions": ["cybernex", "grot"],
        "lods": ["lod0", "lod1", "lod2"],
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
    # When launched via blender --python, args after -- 
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
    args = parser.parse_args(argv)

    input_path = Path(args.input).resolve()
    if not input_path.is_file():
        print(f"ERROR: input not found: {input_path}")
        return 1

    out_dir = PROCESSED / args.name

    # Are we already inside Blender?
    try:
        import bpy  # noqa: F401

        run_inside_blender(input_path, args.name, out_dir)
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
        blender,
        "--background",
        "--python",
        str(Path(__file__).resolve()),
        "--",
        "--input",
        str(input_path),
        "--name",
        args.name,
    ]
    if args.no_assets_copy:
        cmd.append("--no-assets-copy")
    print("→", " ".join(cmd))
    env = os.environ.copy()
    # Headless servers may need xvfb
    if sys.platform.startswith("linux") and not os.getenv("DISPLAY"):
        if shutil.which("xvfb-run"):
            cmd = ["xvfb-run", "-a"] + cmd
    r = subprocess.run(cmd, env=env)
    return r.returncode


if __name__ == "__main__":
    sys.exit(main())
