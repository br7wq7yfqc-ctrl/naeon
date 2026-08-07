extends Node3D
class_name SurfaceFlora
## Near-surface flora / rock density from existing GLBs + procedural stems.
## Snaps with observer — no continuous swim. 0 Tripo.

const REPOS := 22.0
const COUNT_BASE := 14

var _planet: Node3D
var _radius: float = 1200.0
var _observer: Node3D
var _props: Array = []
var _last: Vector3 = Vector3.ZERO
var _has: bool = false
var _accum: float = 0.0
var _seed: int = 1

const ROCKS := [
	"environments/surface_rock_cluster/surface_rock_cluster_cybernex_lod2.glb",
	"colony/surface_crystal_spire/surface_crystal_spire_cybernex_lod2.glb",
	"environments/asteroid_ore/asteroid_ore_cybernex_lod2.glb",
]

func setup(planet: Node3D, radius: float, seed_i: int = 1) -> void:
	_planet = planet
	_radius = radius
	_seed = seed_i

func set_observer(n: Node3D) -> void:
	_observer = n
	_has = false

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.55:
		return
	_accum = 0.0
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	var dist := _observer.global_position.distance_to(_planet.global_position)
	var alt := dist - _radius
	if alt > 120.0 or alt < -8.0:
		_set_vis(false)
		return
	_set_vis(true)
	if _props.is_empty():
		_spawn_pool()
	if (not _has) or _observer.global_position.distance_to(_last) > REPOS:
		_place_around_observer()
		_last = _observer.global_position
		_has = true

func _set_vis(v: bool) -> void:
	for p in _props:
		if p and is_instance_valid(p):
			(p as Node3D).visible = v

func _spawn_pool() -> void:
	var prop_script: Script = load("res://scripts/assets/GlbProp.gd")
	var gq := get_node_or_null("/root/GraphicsQuality")
	var n := COUNT_BASE
	if gq:
		match int(gq.tier):
			0: n = 8
			2, 3: n = 20
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 1337
	for i in n:
		if i % 3 == 0:
			# procedural stem/bush (always available)
			var stem := _make_stem(rng)
			add_child(stem)
			_props.append(stem)
		else:
			var node := Node3D.new()
			node.set_script(prop_script)
			var rel: String = ROCKS[i % ROCKS.size()]
			node.set("relative_path", rel)
			node.set("scale_factor", rng.randf_range(0.4, 1.1))
			node.set("add_static_collision", false)
			add_child(node)
			_props.append(node)
	print("[SurfaceFlora] pool=", _props.size())

func _make_stem(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.12
	cyl.height = rng.randf_range(0.6, 1.8)
	mi.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.35 + rng.randf() * 0.2, 0.14)
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position.y = cyl.height * 0.5
	root.add_child(mi)
	# canopy blob
	var cap := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = rng.randf_range(0.25, 0.55)
	sph.height = sph.radius * 2.0
	cap.mesh = sph
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.15, 0.5 + rng.randf() * 0.25, 0.22)
	cap.material_override = cm
	cap.position.y = cyl.height + sph.radius * 0.4
	root.add_child(cap)
	return root

func _place_around_observer() -> void:
	if _planet == null or _observer == null:
		return
	var up: Vector3 = (_observer.global_position - _planet.global_position).normalized()
	if up.length_squared() < 0.01:
		up = Vector3.UP
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + int(_observer.global_position.x * 0.1)
	# tangent basis
	var tmp := Vector3.RIGHT if absf(up.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
	var right := up.cross(tmp).normalized()
	var fwd := right.cross(up).normalized()
	var i := 0
	for p in _props:
		if p == null or not is_instance_valid(p):
			continue
		var ang := TAU * float(i) / float(maxi(_props.size(), 1)) + rng.randf() * 0.4
		var r := 6.0 + rng.randf() * 28.0
		var offset := (right * cos(ang) + fwd * sin(ang)) * r
		var pos := _planet.global_position + up * (_radius + 0.15) + offset
		# project to sphere
		pos = _planet.global_position + (pos - _planet.global_position).normalized() * (_radius + 0.2)
		(p as Node3D).global_position = pos
		(p as Node3D).look_at(pos + up, right)
		(p as Node3D).rotate_object_local(Vector3.RIGHT, -PI * 0.5)
		i += 1
