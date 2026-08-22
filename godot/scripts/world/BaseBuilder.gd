extends RefCounted
class_name BaseBuilder
## Streams HQ colony props onto a landing pad + PadBaseController (claim/harvest).

const _AP = preload("res://scripts/assets/AssetPaths.gd")
const _Prop = preload("res://scripts/assets/GlbProp.gd")
const _PadCtrl = preload("res://scripts/world/PadBaseController.gd")

static func build_on_pad(pad: Node3D, faction: String) -> void:
	if pad == null or not is_instance_valid(pad):
		return
	if pad.has_meta("base_built") and pad.get_meta("base_built"):
		return
	pad.set_meta("base_built", true)
	pad.set_meta("base_faction", faction)
	var p0 := load("res://scripts/world/P0Slice.gd")
	if p0 and bool(p0.ACTIVE) and bool(p0.ONE_PAD):
		var ctrl0 := Node3D.new()
		ctrl0.set_script(_PadCtrl)
		ctrl0.set("default_faction", faction)
		ctrl0.name = "PadBaseController"
		var root0 := Node3D.new()
		root0.name = "BaseCluster"
		pad.add_child(root0)
		root0.add_child(ctrl0)
		print("[BaseBuilder] P0 controller only on ", pad.name)
		return
	var fx := "cybernex" if faction != "gROT" else "grot"
	var layout: Array = [
		{"rel": "colony/colony_habitat/colony_habitat_%s_lod1.glb" % fx, "pos": Vector3(0, 1.2, -14), "s": 2.2, "id": "habitat"},
		{"rel": "colony/extractor_unit/extractor_unit_%s_lod1.glb" % fx, "pos": Vector3(12, 1.0, 4), "s": 1.4, "id": "extractor"},
		{"rel": "props/turret_emplacement/turret_emplacement_%s_lod1.glb" % fx, "pos": Vector3(-12, 1.0, 4), "s": 1.3, "id": "turret"},
		{"rel": "props/claim_beacon/claim_beacon_%s_lod1.glb" % fx, "pos": Vector3(0, 1.0, 10), "s": 1.1, "id": "beacon"},
		{"rel": "props/control_console/control_console_%s_lod1.glb" % fx, "pos": Vector3(6, 1.0, -6), "s": 1.0, "id": "console"},
		{"rel": "props/med_station/med_station_%s_lod1.glb" % fx, "pos": Vector3(-6, 1.0, -6), "s": 1.0, "id": "med"},
		{"rel": "props/energy_barrier/energy_barrier_%s_lod2.glb" % fx, "pos": Vector3(0, 1.5, 16), "s": 1.6, "id": "barrier"},
		{"rel": "colony/resource_crystal/resource_crystal_%s_lod2.glb" % fx, "pos": Vector3(9, 1.0, -10), "s": 0.9, "id": "crystal"},
	]
	var root := Node3D.new()
	root.name = "BaseCluster"
	pad.add_child(root)
	for e in layout:
		var rel: String = str(e["rel"])
		var path: String = _AP.resolve(rel)
		if path == "" or not FileAccess.file_exists(path):
			rel = rel.replace("_lod1.glb", "_lod2.glb")
			path = _AP.resolve(rel)
		if path == "" or not FileAccess.file_exists(path):
			continue
		var prop: Node3D = Node3D.new()
		prop.set_script(_Prop)
		prop.set("relative_path", rel)
		prop.set("scale_factor", float(e["s"]))
		prop.set("add_static_collision", true)
		prop.name = str(e["id"])
		root.add_child(prop)
		prop.position = e["pos"]

	# Interactive controller at pad center
	var ctrl := Node3D.new()
	ctrl.set_script(_PadCtrl)
	ctrl.set("default_faction", faction)
	ctrl.name = "PadBaseController"
	root.add_child(ctrl)
	print("[BaseBuilder] cluster+controller on ", pad.name, " faction=", faction)


static func is_unnamed_pad(pad: Node) -> bool:
	if pad == null:
		return false
	return str(pad.name) in ["Pad_North", "Pad_Approach", "Pad_Flank"]


static func player_module_on(pad: Node3D) -> Node3D:
	if pad == null or not is_instance_valid(pad):
		return null
	for c in pad.get_children():
		if c is Node3D and c.has_meta("player_module") and bool(c.get_meta("player_module")):
			return c as Node3D
	return pad.find_child("PlayerHabitat", true, false) as Node3D


static func pad_has_player_module(pad: Node3D) -> bool:
	return player_module_on(pad) != null


static func place_player_habitat(pad: Node3D, faction: String) -> Node3D:
	## ST-A: one habitat, code-first. Not a SITE_*, not the OS-G silhouette.
	if pad == null or not is_instance_valid(pad):
		return null
	if not is_unnamed_pad(pad):
		return null
	if pad_has_player_module(pad):
		return null
	var n := Node3D.new()
	n.set_script(preload("res://scripts/world/PlayerBaseModule.gd"))
	n.name = "PlayerHabitat"
	n.set_meta("site_pin", "")
	pad.add_child(n)
	n.position = Vector3(8.0, 2.6, 6.0)
	if n.has_method("setup"):
		n.setup(faction)
	print("[BaseBuilder] player habitat on ", pad.name, " faction=", faction)
	return n
