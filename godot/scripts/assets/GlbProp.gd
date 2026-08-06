extends Node3D

## Loads a GLB from the shared assets/ folder (sibling of godot/).

@export var relative_path: String = "props/sci_fi_crate/sci_fi_crate_cybernex_lod2.glb"
@export var scale_factor: float = 1.0
@export var add_static_collision: bool = true

func _ready() -> void:
	call_deferred("_load")

func _load() -> void:
	var path: String = _resolve_path(relative_path)
	if path == "" or not FileAccess.file_exists(path):
		push_warning("[GlbProp] Missing asset: %s" % relative_path)
		_fallback_mesh()
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err: Error = doc.append_from_file(path, state)
	if err != OK:
		push_warning("[GlbProp] Failed to load %s err=%s" % [path, err])
		_fallback_mesh()
		return
	var root: Node = doc.generate_scene(state)
	if root == null:
		_fallback_mesh()
		return
	add_child(root)
	if scale_factor != 1.0:
		root.scale = Vector3.ONE * scale_factor
	if add_static_collision:
		_add_collision_from_meshes(self)
	print("[GlbProp] Loaded ", path)

func _resolve_path(rel: String) -> String:
	var base: String = ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir()
	var candidate: String = base.path_join("assets").path_join(rel)
	if FileAccess.file_exists(candidate):
		return candidate
	var home: String = OS.get_environment("HOME")
	if home != "":
		var c2: String = home.path_join("Documents/naeon/assets").path_join(rel)
		if FileAccess.file_exists(c2):
			return c2
	return candidate

func _fallback_mesh() -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 1.0, 1.2)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.25, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.7, 0.9)
	mi.material_override = mat
	mi.position.y = 0.5
	add_child(mi)

func _add_collision_from_meshes(node: Node) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	add_child(body)
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(node, meshes)
	for mi in meshes:
		if mi.mesh != null:
			var shape: Shape3D = mi.mesh.create_trimesh_shape()
			if shape != null:
				var cs := CollisionShape3D.new()
				cs.shape = shape
				cs.transform = mi.global_transform * global_transform.affine_inverse()
				body.add_child(cs)
				return
	var cs2 := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 1.0, 1.2)
	cs2.shape = box
	cs2.position.y = 0.5
	body.add_child(cs2)

func _collect_meshes(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for c in n.get_children():
		_collect_meshes(c, out)
