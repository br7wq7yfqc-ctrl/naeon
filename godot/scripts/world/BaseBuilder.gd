extends RefCounted
class_name BaseBuilder
## Streams HQ colony props onto a landing pad (0 Tripo — uses existing dual-theme assets).

const _AP = preload("res://scripts/assets/AssetPaths.gd")
const _Prop = preload("res://scripts/assets/GlbProp.gd")

## Layout offsets in pad local space (Y up).
static func build_on_pad(pad: Node3D, faction: String) -> void:
	if pad == null or not is_instance_valid(pad):
		return
	if pad.has_meta("base_built") and pad.get_meta("base_built"):
		return
	pad.set_meta("base_built", true)
	var fx := "cybernex" if faction != "gROT" else "grot"
	var layout: Array = [
		{"rel": "colony/colony_habitat/colony_habitat_%s_lod1.glb" % fx, "pos": Vector3(0, 1.2, -14), "s": 2.2},
		{"rel": "colony/extractor_unit/extractor_unit_%s_lod1.glb" % fx, "pos": Vector3(12, 1.0, 4), "s": 1.4},
		{"rel": "props/turret_emplacement/turret_emplacement_%s_lod1.glb" % fx, "pos": Vector3(-12, 1.0, 4), "s": 1.3},
		{"rel": "props/claim_beacon/claim_beacon_%s_lod1.glb" % fx, "pos": Vector3(0, 1.0, 10), "s": 1.1},
		{"rel": "props/control_console/control_console_%s_lod1.glb" % fx, "pos": Vector3(6, 1.0, -6), "s": 1.0},
		{"rel": "props/med_station/med_station_%s_lod1.glb" % fx, "pos": Vector3(-6, 1.0, -6), "s": 1.0},
		{"rel": "props/energy_barrier/energy_barrier_%s_lod2.glb" % fx, "pos": Vector3(0, 1.5, 16), "s": 1.6},
		{"rel": "colony/resource_crystal/resource_crystal_%s_lod2.glb" % fx, "pos": Vector3(9, 1.0, -10), "s": 0.9},
	]
	var root := Node3D.new()
	root.name = "BaseCluster"
	pad.add_child(root)
	for e in layout:
		var path: String = _AP.resolve(str(e["rel"]))
		if path == "" or not FileAccess.file_exists(path):
			# fallback lod2
			var rel2: String = str(e["rel"]).replace("_lod1.glb", "_lod2.glb")
			path = _AP.resolve(rel2)
		if path == "" or not FileAccess.file_exists(path):
			continue
		var prop: Node3D = Node3D.new()
		prop.set_script(_Prop)
		prop.set("relative_path", str(e["rel"]))
		prop.set("scale_factor", float(e["s"]))
		prop.set("add_static_collision", true)
		root.add_child(prop)
		prop.position = e["pos"]
	print("[BaseBuilder] cluster on ", pad.name, " faction=", faction)
