extends RefCounted
class_name ProjectilePool
## Recycle MeshInstance3D bolts. Streak mesh + faction mats. Oriented along velocity.

const POOL_MAX := 20

static var _free: Array = []
static var _mesh: BoxMesh = null
static var _head_mesh: SphereMesh = null
static var _mats: Dictionary = {}
static var _active: int = 0
static var _created: int = 0


static func _shared_mesh() -> BoxMesh:
	if _mesh == null:
		var bm := BoxMesh.new()
		bm.size = Vector3(0.07, 0.07, 0.62)
		_mesh = bm
	return _mesh


static func _shared_head() -> SphereMesh:
	if _head_mesh == null:
		var sm := SphereMesh.new()
		sm.radius = 0.11
		sm.height = 0.22
		sm.radial_segments = 8
		sm.rings = 4
		_head_mesh = sm
	return _head_mesh


static func _mat(col: Color) -> StandardMaterial3D:
	var key := "%d_%d_%d" % [int(col.r * 20.0), int(col.g * 20.0), int(col.b * 20.0)]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 3.6
	if _mats.size() > 12:
		_mats.clear()
	_mats[key] = m
	return m


static func spawn(tree: SceneTree, at: Vector3, dir: Vector3, speed: float, dmg: float, faction: String, color: Color, life: float = 1.4) -> MeshInstance3D:
	if tree == null or tree.current_scene == null:
		return null
	if DisplayServer.get_name() == "headless":
		return null
	var bolt: MeshInstance3D = null
	while not _free.is_empty() and bolt == null:
		var cand = _free.pop_back()
		if cand != null and is_instance_valid(cand):
			bolt = cand
	if bolt == null:
		bolt = MeshInstance3D.new()
		bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bolt.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		bolt.mesh = _shared_mesh()
		var runner := Node.new()
		runner.name = "Runner"
		runner.set_script(preload("res://scripts/abilities/ProjectileRunner.gd"))
		bolt.add_child(runner)
		tree.current_scene.add_child(bolt)
		_created += 1
	bolt.mesh = _shared_mesh()
	_ensure_head(bolt)
	bolt.material_override = _mat(color)
	var head := bolt.get_node_or_null("Head") as MeshInstance3D
	if head:
		head.material_override = bolt.material_override
	bolt.visible = true
	bolt.global_position = at
	_orient(bolt, dir)
	bolt.set_meta("direction", dir)
	bolt.set_meta("speed", speed)
	bolt.set_meta("damage", dmg)
	bolt.set_meta("faction", faction)
	bolt.set_meta("life", life)
	bolt.set_meta("pooled", true)
	var r := bolt.get_node_or_null("Runner")
	if r != null and r.has_method("reset"):
		r.reset()
	_active += 1
	return bolt


static func _ensure_head(bolt: MeshInstance3D) -> void:
	if bolt.get_node_or_null("Head") != null:
		return
	var head := MeshInstance3D.new()
	head.name = "Head"
	head.mesh = _shared_head()
	head.position = Vector3(0, 0, -0.32)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	head.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	bolt.add_child(head)


static func _orient(bolt: MeshInstance3D, dir: Vector3) -> void:
	if bolt == null or not bolt.is_inside_tree():
		return
	var n := dir.normalized()
	if n.length_squared() < 0.0001:
		return
	var up := Vector3.UP
	if absf(n.dot(up)) > 0.95:
		up = Vector3.RIGHT
	bolt.look_at(bolt.global_position + n, up)


static func release(bolt: Node) -> void:
	if bolt == null or not is_instance_valid(bolt):
		return
	if not bool(bolt.get_meta("pooled", false)):
		bolt.queue_free()
		return
	bolt.visible = false
	bolt.global_position = Vector3(0.0, -8000.0, 0.0)
	_active = maxi(0, _active - 1)
	if _free.size() < POOL_MAX:
		_free.append(bolt)
	else:
		bolt.set_meta("pooled", false)
		bolt.queue_free()


static func active_count() -> int:
	return _active


static func free_count() -> int:
	return _free.size()


static func created_count() -> int:
	return _created
