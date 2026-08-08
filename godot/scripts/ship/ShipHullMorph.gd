extends Node3D
class_name ShipHullMorph
## Procedural hull morph for operational modes (Siege, Scan, Cargo).

enum OpMode { CRUISE, SIEGE, SCAN, CARGO_OPEN, DOCK_CLAMP }

var op_mode: int = OpMode.CRUISE
var morph_t: float = 0.0
var _plates: Array = []
var _tween: Tween

func _ready() -> void:
	if get_child_count() == 0:
		_build_proxy_plates()
	# Skip GLB radiators on headless (dummy mesh RID → Parameter m is null spam)
	if DisplayServer.get_name() != "headless":
		call_deferred("_try_load_radiator_meshes")


func _build_proxy_plates() -> void:
	_plates.clear()
	var specs: Array = [
		{"name": "Barrel", "pos": Vector3(0, 0.1, -1.2), "size": Vector3(0.15, 0.15, 1.4), "siege_pos": Vector3(0, 0.1, -2.2)},
		{"name": "RadiatorL", "pos": Vector3(-1.1, 0.2, 0.3), "size": Vector3(0.08, 0.6, 0.9), "siege_rot": Vector3(0.6, 0, 0)},
		{"name": "RadiatorR", "pos": Vector3(1.1, 0.2, 0.3), "size": Vector3(0.08, 0.6, 0.9), "siege_rot": Vector3(-0.6, 0, 0)},
		{"name": "Outrigger", "pos": Vector3(0, -0.4, 0.5), "size": Vector3(1.8, 0.08, 0.3), "siege_scale": Vector3(1.5, 1.0, 1.2)},
	]
	for s in specs:
		var mi := MeshInstance3D.new()
		mi.name = str(s["name"])
		var box := BoxMesh.new()
		box.size = s["size"]
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.55, 0.75, 0.9)
		mat.metallic = 0.7
		mat.roughness = 0.35
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.6, 0.9)
		mat.emission_energy_multiplier = 0.4
		mi.material_override = mat
		add_child(mi)
		mi.position = s["pos"]
		mi.visible = false
		var base_xf := mi.transform
		var siege_xf := base_xf
		if s.has("siege_pos"):
			siege_xf.origin = s["siege_pos"]
		if s.has("siege_rot"):
			var e: Vector3 = s["siege_rot"]
			siege_xf.basis = Basis.from_euler(e) * base_xf.basis
		if s.has("siege_scale"):
			siege_xf.basis = siege_xf.basis.scaled(s["siege_scale"])
		_plates.append({"node": mi, "base": base_xf, "siege": siege_xf})


func set_op_mode(mode: int, enter_sec: float = 1.0) -> void:
	if mode == op_mode:
		return
	op_mode = mode
	var target := 0.0
	if mode == OpMode.SIEGE:
		target = 1.0
	elif mode == OpMode.SCAN:
		target = 0.55
	elif mode == OpMode.CARGO_OPEN:
		target = 0.85
	if _tween and is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply_morph_t, morph_t, target, maxf(enter_sec, 0.05))


func _apply_morph_t(t: float) -> void:
	morph_t = clampf(t, 0.0, 1.0)
	for p in _plates:
		var n: Node3D = p["node"]
		if n == null or not is_instance_valid(n):
			continue
		var a: Transform3D = p["base"]
		var b: Transform3D = p["siege"]
		n.transform = a.interpolate_with(b, morph_t)
		n.visible = morph_t > 0.02
		if n is MeshInstance3D and (n as MeshInstance3D).material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = (n as MeshInstance3D).material_override
			mat.emission_energy_multiplier = 0.4 + morph_t * 2.2


func op_mode_name() -> String:
	match op_mode:
		OpMode.SIEGE:
			return "SIEGE"
		OpMode.SCAN:
			return "SCAN"
		OpMode.CARGO_OPEN:
			return "CARGO"
		OpMode.DOCK_CLAMP:
			return "DOCK"
		_:
			return "CRUISE"


func _try_load_radiator_meshes() -> void:
	_try_load_variable_wing()
	var AP = load("res://scripts/assets/AssetPaths.gd")
	if AP == null:
		return
	var fac := "cybernex"
	var ship := get_parent()
	if ship and "faction" in ship and str(ship.faction) == "gROT":
		fac = "grot"
	var rel := "ships/ship_siege_radiator/ship_siege_radiator_%s_lod1.glb" % fac
	var path: String = ""
	if AP.has_method("resolve"):
		path = str(AP.resolve(rel))
	if path == "" or not FileAccess.file_exists(path):
		return
	for side in [-1.0, 1.0]:
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(path, st) != OK:
			continue
		var scn := doc.generate_scene(st)
		if scn == null:
			continue
		_strip_empty_meshes(scn)
		add_child(scn)
		scn.name = "RadiatorGLB_%s" % ("L" if side < 0 else "R")
		scn.scale = Vector3.ONE * 0.55
		var base := Transform3D(Basis.IDENTITY, Vector3(side * 1.15, 0.25, 0.2))
		var siege := Transform3D(Basis.from_euler(Vector3(side * 0.55, 0, 0)), Vector3(side * 1.35, 0.15, 0.1))
		scn.transform = base
		scn.visible = false
		_plates.append({"node": scn, "base": base, "siege": siege})
	print("[HullMorph] siege radiators loaded")


func _strip_empty_meshes(n: Node) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		if mi.mesh == null:
			n.queue_free()
			return
	for c in n.get_children():
		_strip_empty_meshes(c)


func _try_load_variable_wing() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var AP = load("res://scripts/assets/AssetPaths.gd")
	if AP == null:
		return
	var fac := "cybernex"
	var ship := get_parent()
	if ship and "faction" in ship and str(ship.faction) == "gROT":
		fac = "grot"
	var rel := "ships/ship_variable_wing/ship_variable_wing_%s_lod1.glb" % fac
	var path: String = str(AP.resolve(rel)) if AP.has_method("resolve") else ""
	if path == "" or not FileAccess.file_exists(path):
		return
	for side in [-1.0, 1.0]:
		var doc := GLTFDocument.new()
		var st2 := GLTFState.new()
		if doc.append_from_file(path, st2) != OK:
			continue
		var scn := doc.generate_scene(st2)
		if scn == null:
			continue
		add_child(scn)
		scn.position = Vector3(side * 1.4, 0.1, 0.2)
		scn.scale = Vector3.ONE * 0.45
		scn.scale.x *= side
		_plates.append({"node": scn, "base": scn.transform, "siege": scn.transform.translated(Vector3(side * 0.4, 0, -0.3))})
	print("[HullMorph] variable wing loaded")
