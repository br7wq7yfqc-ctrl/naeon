#!/usr/bin/env python3
"""
NAEON Blender processor (economical):
  - LOD0/1/2 decimation (unique mesh + COLLAPSE triangulate; optional --max-verts)
  - dual-theme Cybernex / gROT materials
  - optional --keep-materials (preserve Tripo PBR, tint only)
  - optional --no-tint (keep Tripo PBR with no faction mix)
  - optional --faction cybernex|grot (export that faction only + unfactioned lod alias)
  - optional --wear (extra worn/damaged material variants — free multiplication)
  - optional --stand-up (longest axis → Blender Z / glTF Y before 1.5 m normalize)
  - optional --max-tex (resize images; pad props 1024)
  - export the LOD object only (never base+lod in one GLB)
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
    faction: str | None = None,
    no_tint: bool = False,
    lod_ratios: tuple[float, float, float] | None = None,
    max_verts: tuple[int, int, int] | None = None,
    stand_up: bool = False,
    max_tex: int = 0,
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
    # Unique datablock so Decimate actually writes (shared mesh = silent no-op).
    if base.data.users > 1:
        base.data = base.data.copy()

    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    base.select_set(True)
    bpy.context.view_layer.objects.active = base

    if stand_up:
        bpy.context.view_layer.update()
        base.rotation_mode = "XYZ"
        d = base.dimensions
        # Longest axis → Blender Z (glTF Y). Skip if already standing.
        if d.x >= d.y and d.x > d.z * 1.05:
            base.rotation_euler = (0.0, 1.57079632679, 0.0)
        elif d.y >= d.x and d.y > d.z * 1.05:
            base.rotation_euler = (-1.57079632679, 0.0, 0.0)
        bpy.context.view_layer.update()
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        bpy.context.view_layer.update()

    # Normalize scale to ~1.5m height
    dims = base.dimensions
    max_dim = max(dims.x, dims.y, dims.z) or 1.0
    target = 1.5
    if max_dim > 0.001:
        s = target / max_dim
        base.scale = (s, s, s)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    if max_tex and max_tex > 0:
        for img in bpy.data.images:
            w, h = int(img.size[0]), int(img.size[1])
            if w > max_tex or h > max_tex:
                img.scale(max_tex, max_tex)

    # Store original material slots if keep
    orig_mats = list(base.data.materials) if base.data.materials else []

    def export_glb(path: Path, obj=None) -> None:
        bpy.ops.object.select_all(action="DESELECT")
        if obj is not None:
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
        else:
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
                            if col and not no_tint:
                                c = list(col.default_value)
                                col.default_value = (
                                    c[0] * 0.55 + tint[0] * 0.45,
                                    c[1] * 0.55 + tint[1] * 0.45,
                                    c[2] * 0.55 + tint[2] * 0.45,
                                    1.0,
                                )
                            if emis and not no_tint:
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

    def _decimate(obj, ratio: float, cap: int) -> None:
        """COLLAPSE+triangulate on a unique mesh. Repeat if still over cap.
        Default 0.45/0.18 was a no-op on shared Tripo datablocks (~76% left)."""
        if obj.data.users > 1:
            obj.data = obj.data.copy()
        bpy.ops.object.mode_set(mode="OBJECT")
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        steps = 0
        while True:
            n = len(obj.data.vertices)
            need_ratio = ratio < 0.999
            need_cap = cap > 0 and n > cap
            if not need_ratio and not need_cap:
                break
            r = ratio if steps == 0 and need_ratio else 1.0
            if need_cap:
                r = min(r, max(0.02, cap / float(n)))
            if r >= 0.999:
                break
            mod = obj.modifiers.new(name=f"Decimate{steps}", type="DECIMATE")
            mod.decimate_type = "COLLAPSE"
            mod.ratio = r
            try:
                mod.use_collapse_triangulate = True
            except Exception:
                pass
            bpy.ops.object.modifier_apply(modifier=mod.name)
            n2 = len(obj.data.vertices)
            print(f"  decimate {obj.name} {n} -> {n2} r={r:.3f} cap={cap}")
            steps += 1
            if n2 >= n * 0.98 or steps >= 4:
                break
            ratio = 1.0  # further loops only honor cap

    lod_map = [("lod0", 1.0), ("lod1", 0.45), ("lod2", 0.18)]
    if lod_ratios and len(lod_ratios) == 3:
        lod_map = [("lod0", lod_ratios[0]), ("lod1", lod_ratios[1]), ("lod2", lod_ratios[2])]
    lod_caps = (0, 0, 0)
    if max_verts and len(max_verts) == 3:
        lod_caps = max_verts
    variants = [("clean", False)]
    if wear:
        variants.append(("worn", True))

    factions = (faction,) if faction in ("cybernex", "grot") else ("cybernex", "grot")

    exports: list[str] = []
    for fac in factions:
        for vname, worn in variants:
            for lod_i, (lod_name, ratio) in enumerate(lod_map):
                bpy.ops.object.select_all(action="DESELECT")
                base.select_set(True)
                bpy.context.view_layer.objects.active = base
                bpy.ops.object.duplicate()
                obj = bpy.context.view_layer.objects.active
                if obj.data.users > 1:
                    obj.data = obj.data.copy()
                suffix = f"{fac}_{vname}_{lod_name}" if wear else f"{fac}_{lod_name}"
                obj.name = f"{name}_{suffix}"
                _decimate(obj, ratio, lod_caps[lod_i])
                apply_faction_material(obj, fac, worn=worn)
                out_path = out_dir / f"{name}_{suffix}.glb"
                export_glb(out_path, obj)
                exports.append(str(out_path))
                if faction in ("cybernex", "grot") and not wear:
                    alias = out_dir / f"{name}_{lod_name}.glb"
                    shutil.copy2(out_path, alias)
                    exports.append(str(alias))
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
        "factions": list(factions),
        "lods": ["lod0", "lod1", "lod2"],
        "keep_materials": keep_materials,
        "no_tint": no_tint,
        "wear": wear,
        "stand_up": stand_up,
        "max_tex": max_tex,
        "lod_ratios": list(lod_ratios) if lod_ratios else [1.0, 0.45, 0.18],
        "max_verts": list(max_verts) if max_verts else [0, 0, 0],
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
    parser.add_argument("--no-tint", action="store_true", help="With --keep-materials, do not mix faction tint")
    parser.add_argument("--faction", choices=["cybernex", "grot"], default=None,
                        help="Export only this faction (locked dual-theme plates)")
    parser.add_argument("--wear", action="store_true", help="Also export worn material variants (free ×2)")
    parser.add_argument("--lod-ratios", default="",
                        help="Comma triple lod0,lod1,lod2 collapse ratios (default 1.0,0.45,0.18)")
    parser.add_argument("--max-verts", default="",
                        help="Comma triple lod0,lod1,lod2 vertex caps (0 = off). Repeat collapse until cap.")
    parser.add_argument("--stand-up", action="store_true",
                        help="Rotate longest axis to Blender Z (glTF Y) before normalize")
    parser.add_argument("--max-tex", type=int, default=0,
                        help="Resize images above this edge (0 = leave Tripo res)")
    args = parser.parse_args(argv)

    def _triple_f(raw: str):
        if not raw:
            return None
        parts = [float(x.strip()) for x in raw.split(",") if x.strip()]
        if len(parts) != 3:
            raise SystemExit(f"want 3 comma values, got {raw!r}")
        return (parts[0], parts[1], parts[2])

    def _triple_i(raw: str):
        if not raw:
            return None
        parts = [int(x.strip()) for x in raw.split(",") if x.strip()]
        if len(parts) != 3:
            raise SystemExit(f"want 3 comma ints, got {raw!r}")
        return (parts[0], parts[1], parts[2])

    lod_ratios = _triple_f(args.lod_ratios)
    max_verts = _triple_i(args.max_verts)

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
            faction=args.faction,
            no_tint=args.no_tint,
            lod_ratios=lod_ratios,
            max_verts=max_verts,
            stand_up=args.stand_up,
            max_tex=args.max_tex,
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
    if args.no_tint:
        cmd.append("--no-tint")
    if args.faction:
        cmd.extend(["--faction", args.faction])
    if args.wear:
        cmd.append("--wear")
    if args.lod_ratios:
        cmd.extend(["--lod-ratios", args.lod_ratios])
    if args.max_verts:
        cmd.extend(["--max-verts", args.max_verts])
    if args.stand_up:
        cmd.append("--stand-up")
    if args.max_tex:
        cmd.extend(["--max-tex", str(args.max_tex)])
    print("→", " ".join(cmd))
    env = os.environ.copy()
    if sys.platform.startswith("linux") and not os.getenv("DISPLAY"):
        if shutil.which("xvfb-run"):
            cmd = ["xvfb-run", "-a"] + cmd
    return subprocess.run(cmd, env=env).returncode


if __name__ == "__main__":
    sys.exit(main())
