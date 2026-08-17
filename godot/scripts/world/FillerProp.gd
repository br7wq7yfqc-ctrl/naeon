extends Node3D
class_name FillerProp
## One unnamed WorldFill prop from the P0 manifest. Code-first proxy until
## the CC0 GLB is on s3://neon. Never a SITE_*. Never a binary in git.

const MANIFEST := "res://../docs/design/p0_filler_manifest.json"
const _AP = preload("res://scripts/assets/AssetPaths.gd")

@export var prop_id: String = "pad_crate_cc0"
@export var scale_factor: float = 1.0
@export var far_read: bool = false

var _entry: Dictionary = {}


func setup(id: String = "pad_crate_cc0") -> void:
	prop_id = id
	_entry = _find(id)
	_build()


func _ready() -> void:
	if _entry.is_empty():
		setup(prop_id)


func manifest_id() -> String:
	return str(_entry.get("id", prop_id))


func source_line() -> String:
	if _entry.is_empty():
		return ""
	return "%s · %s · %s" % [
		str(_entry.get("source", "?")),
		str(_entry.get("license", "?")),
		str(_entry.get("url", "")),
	]


func _find(id: String) -> Dictionary:
	var path := _manifest_path()
	if path == "" or not FileAccess.file_exists(path):
		return {"id": id, "source": "missing-manifest", "license": "CC0-1.0", "url": ""}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	for e in data.get("props", []):
		if typeof(e) == TYPE_DICTIONARY and str(e.get("id", "")) == id:
			return e
	return {}


func _manifest_path() -> String:
	var godot_root := ProjectSettings.globalize_path("res://").rstrip("/")
	var repo_root := godot_root.get_base_dir()
	var p := repo_root.path_join("docs/design/p0_filler_manifest.json")
	if FileAccess.file_exists(p):
		return p
	var alt := godot_root.path_join("../docs/design/p0_filler_manifest.json")
	if FileAccess.file_exists(alt):
		return alt
	if FileAccess.file_exists(MANIFEST):
		return MANIFEST
	return p


func _kind() -> String:
	return str(_entry.get("kind", "crate"))


func ledger_slug() -> String:
	return str(_entry.get("ledger_slug", get_meta("ledger_slug", "")))


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var rel := str(_entry.get("local_rel", "filler/wooden_crate_01/wooden_crate_01.glb"))
	var path: String = _AP.resolve(rel)
	if DisplayServer.get_name() != "headless" and path != "" and FileAccess.file_exists(path):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(path, state) == OK:
			var root := doc.generate_scene(state)
			if root:
				add_child(root)
				root.scale = Vector3.ONE * (1.4 * maxf(scale_factor, 0.2))
				_tag()
				print("[FillerProp] loaded ", path)
				return
	_spawn_proxy()
	_tag()
	print("[FillerProp] proxy ", manifest_id(), " ", source_line())


func _spawn_proxy() -> void:
	if DisplayServer.get_name() == "headless":
		return
	match _kind():
		"rock":
			_spawn_rock_proxy()
		"debris":
			_spawn_debris_proxy()
		"mast":
			_spawn_mast_proxy()
		"extractor":
			_spawn_extractor_proxy()
		"utility":
			_spawn_utility_proxy()
		_:
			_spawn_crate_proxy()
	if far_read:
		_spawn_far_read()


func _spawn_crate_proxy() -> void:
	var s := maxf(scale_factor, 0.2)
	var mi := MeshInstance3D.new()
	mi.name = "Proxy"
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 1.4, 1.6) * s
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.42, 0.32, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(0.28, 0.20, 0.10)
	mat.emission_energy_multiplier = 0.45
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_near_range(mi)
	add_child(mi)
	var band := MeshInstance3D.new()
	var strap := BoxMesh.new()
	strap.size = Vector3(1.66, 0.12, 1.66) * s
	band.mesh = strap
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(0.22, 0.2, 0.16)
	band.material_override = sm
	band.position.y = 0.15 * s
	_near_range(band)
	add_child(band)


func _spawn_rock_proxy() -> void:
	var s := maxf(scale_factor, 0.2)
	var mat := _mat(Color(0.36, 0.32, 0.26), Color(0.20, 0.18, 0.14), 0.5)
	var core := MeshInstance3D.new()
	core.name = "Proxy"
	var box := BoxMesh.new()
	box.size = Vector3(2.4, 1.6, 2.1) * s
	core.mesh = box
	core.material_override = mat
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_near_range(core)
	add_child(core)
	var cap := MeshInstance3D.new()
	var cap_box := BoxMesh.new()
	cap_box.size = Vector3(1.5, 1.1, 1.7) * s
	cap.mesh = cap_box
	cap.material_override = mat
	cap.position = Vector3(0.35 * s, 0.55 * s, -0.15 * s)
	cap.rotation = Vector3(0.2, 0.4, 0.15)
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_near_range(cap)
	add_child(cap)


func _spawn_debris_proxy() -> void:
	var s := maxf(scale_factor, 0.2)
	var mat := _mat(Color(0.34, 0.30, 0.26), Color(0.22, 0.18, 0.14), 0.55)
	var hunks: Array = [
		[Vector3(3.4, 1.6, 2.6) * s, Vector3.ZERO],
		[Vector3(1.8, 1.1, 2.2) * s, Vector3(1.3 * s, 0.35 * s, 0.4 * s)],
		[Vector3(2.1, 0.9, 1.4) * s, Vector3(-1.1 * s, 0.2 * s, -0.8 * s)],
	]
	for i in hunks.size():
		var mi := MeshInstance3D.new()
		mi.name = "Proxy" if i == 0 else "Hunk_%d" % i
		var box := BoxMesh.new()
		box.size = hunks[i][0]
		mi.mesh = box
		mi.position = hunks[i][1]
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_near_range(mi)
		add_child(mi)


func _spawn_mast_proxy() -> void:
	var s := maxf(scale_factor, 0.2)
	var mat := _mat(Color(0.40, 0.44, 0.48), Color(0.22, 0.28, 0.32), 0.7)
	var shaft := MeshInstance3D.new()
	shaft.name = "Proxy"
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 14.0, 0.9) * s
	shaft.mesh = box
	shaft.position.y = 7.0 * s
	shaft.material_override = mat
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_near_range(shaft)
	add_child(shaft)
	var arm := MeshInstance3D.new()
	var arm_box := BoxMesh.new()
	arm_box.size = Vector3(4.2, 0.35, 0.35) * s
	arm.mesh = arm_box
	arm.position = Vector3(0.8 * s, 11.2 * s, 0.0)
	arm.material_override = mat
	_near_range(arm)
	add_child(arm)


func _spawn_extractor_proxy() -> void:
	var s := maxf(scale_factor, 0.2)
	var mat := _mat(Color(0.20, 0.24, 0.28), Color(0.12, 0.16, 0.18), 0.6)
	var hall := MeshInstance3D.new()
	hall.name = "Proxy"
	var box := BoxMesh.new()
	box.size = Vector3(6.4, 3.6, 5.2) * s
	hall.mesh = box
	hall.position.y = 1.8 * s
	hall.material_override = mat
	hall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_near_range(hall)
	add_child(hall)
	var stack := MeshInstance3D.new()
	var st := BoxMesh.new()
	st.size = Vector3(1.4, 5.2, 1.4) * s
	stack.mesh = st
	stack.position = Vector3(1.6 * s, 4.4 * s, -0.6 * s)
	stack.material_override = mat
	_near_range(stack)
	add_child(stack)


func _spawn_utility_proxy() -> void:
	var s := maxf(scale_factor, 0.2)
	var mat := _mat(Color(0.28, 0.30, 0.32), Color(0.16, 0.18, 0.20), 0.5)
	var bay := MeshInstance3D.new()
	bay.name = "Proxy"
	var box := BoxMesh.new()
	box.size = Vector3(5.2, 2.2, 3.6) * s
	bay.mesh = box
	bay.position.y = 1.1 * s
	bay.material_override = mat
	bay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_near_range(bay)
	add_child(bay)


func _spawn_far_read() -> void:
	var s := maxf(scale_factor, 0.2) * 2.4
	var kind := _kind()
	var size := Vector3(4.0, 3.0, 4.0) * s
	var y := size.y * 0.5
	match kind:
		"mast":
			size = Vector3(2.4, 28.0, 2.4) * maxf(scale_factor, 0.2)
			y = size.y * 0.5
		"debris":
			size = Vector3(18.0, 8.0, 14.0)
			y = 4.0
		"extractor":
			size = Vector3(16.0, 14.0, 12.0)
			y = 7.0
		"utility":
			size = Vector3(12.0, 7.0, 9.0)
			y = 3.5
		"rock":
			size = Vector3(14.0, 8.0, 12.0)
			y = 4.0
		_:
			size = Vector3(8.0, 6.0, 8.0)
			y = 3.0
	var mi := MeshInstance3D.new()
	mi.name = "FarProxy"
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position.y = y
	mi.material_override = _mat(Color(0.38, 0.36, 0.32), Color(0.24, 0.22, 0.18), 0.85)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.visibility_range_begin = 80.0
	mi.visibility_range_begin_margin = 20.0
	mi.visibility_range_end = 3200.0
	mi.visibility_range_end_margin = 240.0
	add_child(mi)


func _mat(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = albedo
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = energy
	return mat


func _near_range(mi: GeometryInstance3D) -> void:
	mi.visibility_range_end = 420.0
	mi.visibility_range_end_margin = 40.0


func _tag() -> void:
	set_meta("filler_prop", true)
	set_meta("filler_id", manifest_id())
	set_meta("site_pin", "")
	var slug := str(_entry.get("ledger_slug", ""))
	if slug != "":
		set_meta("ledger_slug", slug)
	add_to_group("filler_props")
