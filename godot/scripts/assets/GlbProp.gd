extends Node3D

const _AP = preload("res://scripts/assets/AssetPaths.gd")

@export var relative_path: String = "props/sci_fi_crate/sci_fi_crate_cybernex_lod2.glb"
@export var scale_factor: float = 1.0
@export var add_static_collision: bool = true

func _ready() -> void:
	_load_prop()


func _load_prop() -> void:
	# Headless/dummy mesh storage cannot register glTF RIDs → ERROR Parameter m is null spam
	if DisplayServer.get_name() == "headless":
		_spawn_proxy()
		return
	var path: String = _AP.resolve(relative_path)
	if not FileAccess.file_exists(path):
		push_warning("[GlbProp] Missing: %s" % path)
		_spawn_proxy()
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err: Error = doc.append_from_file(path, state)
	if err != OK:
		push_warning("[GlbProp] GLTF fail %s: %s" % [path, err])
		_spawn_proxy()
		return
	var root: Node = doc.generate_scene(state)
	if root == null:
		_spawn_proxy()
		return
	add_child(root)
	root.scale = Vector3.ONE * scale_factor
	if add_static_collision:
		_add_simple_collision()
	print("[GlbProp] Loaded ", path)


func _spawn_proxy() -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.8
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.55, 0.7)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.scale = Vector3.ONE * scale_factor
	if add_static_collision:
		_add_simple_collision()


func _add_simple_collision() -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * 0.9 * scale_factor
	col.shape = box
	body.add_child(col)
	add_child(body)


func reload_for_faction(faction: String) -> void:
	var fx := "cybernex" if faction != "gROT" else "grot"
	var rel: String = relative_path
	if "_cybernex_" in rel:
		rel = rel.replace("_cybernex_", "_%s_" % fx)
	elif "_grot_" in rel:
		rel = rel.replace("_grot_", "_%s_" % fx)
	else:
		return
	if rel == relative_path:
		return
	relative_path = rel
	for c in get_children():
		remove_child(c)
		c.free()
	_load_prop()
	print("[GlbProp] theme → ", faction, " ", relative_path)
