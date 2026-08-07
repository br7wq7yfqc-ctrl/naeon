extends Node3D
class_name SurfaceFlora
## Near-surface flora / rock density. Snaps to planet surface GRID (not player orbit).

const CELL_M := 40.0
const COUNT_BASE := 14

var _planet: Node3D
var _radius: float = 1200.0
var _observer: Node3D
var _props: Array = []
var _last_cell: Vector2i = Vector2i(999999, 999999)
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
	_last_cell = Vector2i(999999, 999999)


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
	var cell := _surface_cell(_observer.global_position)
	if cell != _last_cell:
		_last_cell = cell
		_place_cell(cell)


func _surface_cell(global_pos: Vector3) -> Vector2i:
	var local: Vector3 = (global_pos - _planet.global_position).normalized()
	var lat := asin(clampf(local.y, -1.0, 1.0))
	var lon := atan2(local.x, local.z)
	var cell_ang := CELL_M / maxf(_radius, 1.0)
	return Vector2i(int(floor(lon / cell_ang)), int(floor(lat / cell_ang)))


func _stable_tangent(up: Vector3) -> Array:
	up = up.normalized()
	var ref := Vector3.UP
	if absf(up.dot(ref)) > 0.92:
		ref = Vector3.RIGHT
	var east := ref.cross(up).normalized()
	var north := up.cross(east).normalized()
	return [east, north]


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
			2, 3: n = 18
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 1337
	for i in n:
		if i % 3 == 0:
			var stem := _make_stem(rng)
			add_child(stem)
			_props.append(stem)
		else:
			var node := Node3D.new()
			node.set_script(prop_script)
			node.set("relative_path", ROCKS[i % ROCKS.size()])
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


func _place_cell(cell: Vector2i) -> void:
	if _planet == null:
		return
	var cell_ang := CELL_M / maxf(_radius, 1.0)
	var lon := (float(cell.x) + 0.5) * cell_ang
	var lat := (float(cell.y) + 0.5) * cell_ang
	var clat := cos(lat)
	var center := Vector3(sin(lon) * clat, sin(lat), cos(lon) * clat).normalized()
	var t := _stable_tangent(center)
	var east: Vector3 = t[0]
	var north: Vector3 = t[1]
	# Deterministic scatter from cell coords (stable across visits)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 10007 + cell.x * 131 + cell.y * 9176
	var i := 0
	for p in _props:
		if p == null or not is_instance_valid(p):
			continue
		var ang := rng.randf() * TAU
		var r := 3.0 + rng.randf() * 22.0
		var offset := (east * cos(ang) + north * sin(ang)) * r
		var dir := (center * _radius + offset).normalized()
		var pos: Vector3 = _planet.global_position + dir * (_radius + 0.2)
		var up := dir
		(p as Node3D).global_position = pos
		# Align stem to radial up without look_at flip spam
		var tt := _stable_tangent(up)
		(p as Node3D).global_transform = Transform3D(Basis(tt[0], up, -tt[1]), pos)
		i += 1
