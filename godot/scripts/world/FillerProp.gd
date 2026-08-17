extends Node3D
class_name FillerProp
## One unnamed WorldFill prop from the P0 manifest. Code-first proxy until
## the CC0 GLB is on s3://neon. Never a SITE_*. Never a binary in git.

const MANIFEST := "res://../docs/design/p0_filler_manifest.json"
const _AP = preload("res://scripts/assets/AssetPaths.gd")

@export var prop_id: String = "pad_crate_cc0"
@export var scale_factor: float = 1.0

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
	if _kind() == "rock":
		_spawn_rock_proxy()
		return
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
	add_child(band)


func _spawn_rock_proxy() -> void:
	var s := maxf(scale_factor, 0.2)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.36, 0.32, 0.26)
	mat.emission_enabled = true
	mat.emission = Color(0.20, 0.18, 0.14)
	mat.emission_energy_multiplier = 0.5
	var core := MeshInstance3D.new()
	core.name = "Proxy"
	var box := BoxMesh.new()
	box.size = Vector3(2.4, 1.6, 2.1) * s
	core.mesh = box
	core.material_override = mat
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)
	var cap := MeshInstance3D.new()
	var cap_box := BoxMesh.new()
	cap_box.size = Vector3(1.5, 1.1, 1.7) * s
	cap.mesh = cap_box
	cap.material_override = mat
	cap.position = Vector3(0.35 * s, 0.55 * s, -0.15 * s)
	cap.rotation = Vector3(0.2, 0.4, 0.15)
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cap)


func _tag() -> void:
	set_meta("filler_prop", true)
	set_meta("filler_id", manifest_id())
	set_meta("site_pin", "")
	add_to_group("filler_props")
