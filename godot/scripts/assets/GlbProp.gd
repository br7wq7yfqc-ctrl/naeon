extends Node3D

const _AP = preload("res://scripts/assets/AssetPaths.gd")

@export var relative_path: String = "props/sci_fi_crate/sci_fi_crate_cybernex_lod2.glb"
@export var scale_factor: float = 1.0
@export var add_static_collision: bool = true

func _ready() -> void:
	_load_prop()

func _load_prop() -> void:
	var path: String = _AP.resolve(relative_path)
	if not FileAccess.file_exists(path):
		push_warning("[GlbProp] Missing: %s" % path)
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err: Error = doc.append_from_file(path, state)
	if err != OK:
		push_warning("[GlbProp] GLTF fail %s: %s" % [path, err])
		return
	var root: Node = doc.generate_scene(state)
	if root == null:
		return
	add_child(root)
	root.scale = Vector3.ONE * scale_factor
	if add_static_collision:
		_add_collision_from_meshes(root)
	print("[GlbProp] Loaded ", path)

func _add_collision_from_meshes(n: Node) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		if mi.mesh:
			var body := StaticBody3D.new()
			var col := CollisionShape3D.new()
			col.shape = mi.mesh.create_trimesh_shape()
			body.add_child(col)
			mi.add_child(body)
	for c in n.get_children():
		_add_collision_from_meshes(c)

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
