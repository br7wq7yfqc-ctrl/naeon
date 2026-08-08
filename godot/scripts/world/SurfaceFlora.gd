extends Node3D
class_name SurfaceFlora
## Flora/rocks stream on same cell grid as SurfaceDetail. Pool never respawns.

const _Math = preload("res://scripts/world/SurfaceChunkMath.gd")
const _Relief = preload("res://scripts/world/PlanetRelief.gd")
const CELL_M := 40.0
const COUNT_BASE := 18
const STREAM_HZ := 0.5

var _planet: Node3D
var _radius: float = 1200.0
var _observer: Node3D
var _props: Array = []
var _last_cell: Vector2i = Vector2i(999999, 999999)
var _accum: float = 0.0
var _seed: int = 1
var _built: bool = false
var _planet_id: String = "Nex-Prime"
var _relief_profile: Dictionary = {}

const ROCKS := [
	"environments/surface_rock_cluster/surface_rock_cluster_cybernex_lod2.glb",
	"colony/surface_crystal_spire/surface_crystal_spire_cybernex_lod2.glb",
	"environments/asteroid_ore/asteroid_ore_cybernex_lod2.glb",
]


func setup(planet: Node3D, radius: float, seed_i: int = 1) -> void:
	_planet = planet
	_radius = radius
	_seed = seed_i
	if planet != null and "planet_name" in planet:
		_planet_id = str(planet.planet_name)
	_relief_profile = _Relief.profile_for_planet(_planet_id)


func set_observer(n: Node3D) -> void:
	_observer = n
	_last_cell = Vector2i(999999, 999999)


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_accum += delta
	var hz := STREAM_HZ
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and int(gq.tier) == 0:
		hz = 0.75
	elif gq and int(gq.tier) == 1:
		hz = STREAM_HZ * 1.25
	if _accum < hz:
		return
	_accum = 0.0
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	var dist := _observer.global_position.distance_to(_planet.global_position)
	var alt := dist - _radius
	if alt > 100.0 or alt < -8.0:
		_set_vis(false)
		return
	_set_vis(true)
	if not _built:
		_spawn_pool()
		_built = true
	var cell: Vector2i = _Math.cell_of(_planet.global_position, _radius, _observer.global_position, CELL_M)
	if cell != _last_cell:
		_last_cell = cell
		_place_cell(cell)


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
			0: n = 7
			2, 3: n = 16
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 1337
	for i in n:
		if i % 3 == 0:
			add_child(_make_stem(rng))
			_props.append(get_child(get_child_count() - 1))
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
	var xf := _Math.cell_transform(_planet.global_position, _radius, cell, CELL_M, 0.2)
	var east: Vector3 = xf.basis.x
	var up: Vector3 = xf.basis.y
	var north: Vector3 = -xf.basis.z
	var center: Vector3 = up
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 10007 + cell.x * 131 + cell.y * 9176
	var sea_l: float = float(_relief_profile.get("sea_level", -0.35))
	var mtn: float = float(_relief_profile.get("mountain_amp", 6.0))
	for p in _props:
		if p == null or not is_instance_valid(p):
			continue
		var ang := rng.randf() * TAU
		var r := 2.0 + rng.randf() * 24.0
		var offset := (east * cos(ang) + north * sin(ang)) * r
		var dir := (center * _radius + offset).normalized()
		var wx := float(cell.x) * CELL_M + offset.dot(east)
		var wz := float(cell.y) * CELL_M + offset.dot(north)
		var rh: float = float(_Relief.height_at(wx, wz, _seed, _relief_profile))
		# No flora in deep water or high alpine peaks
		if rh < sea_l + 0.12 or rh > mtn * 0.85:
			(p as Node3D).visible = false
			continue
		# Prefer mid slopes / shore band density
		var shore_band := absf(rh - sea_l) < 1.5
		if not shore_band and rng.randf() > 0.55:
			(p as Node3D).visible = false
			continue
		(p as Node3D).visible = true
		var pos: Vector3 = _planet.global_position + dir * (_radius + 0.25 + maxf(rh, 0.0) * 0.05)
		var pup := dir
		var tt: Array = _Math.stable_tangent(pup)
		var sc := 0.85 + rng.randf() * 0.5
		if shore_band:
			sc *= 1.15
		(p as Node3D).global_transform = Transform3D(Basis(tt[0], pup, -tt[1]).scaled(Vector3.ONE * sc), pos)
