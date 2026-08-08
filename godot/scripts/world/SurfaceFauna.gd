extends Node3D
class_name SurfaceFauna
## Streamed fauna proxies by biome domain. Visual life only — no combat power.

const _Math = preload("res://scripts/world/SurfaceChunkMath.gd")
const _Cat = preload("res://scripts/world/FaunaCatalog.gd")
const _AP = preload("res://scripts/assets/AssetPaths.gd")

const CELL_M := 48.0
const COUNT_BASE := 10
const STREAM_HZ := 0.4

var _planet: Node3D
var _radius: float = 1200.0
var _atm: float = 300.0
var _observer: Node3D
var _actors: Array = []
var _last_cell: Vector2i = Vector2i(999999, 999999)
var _accum: float = 0.0
var _seed: int = 1
var _built: bool = false
var _planet_id: String = "Nex-Prime"
var _biomes: PackedStringArray = PackedStringArray()


func setup(planet: Node3D, radius: float, atmosphere_height: float, planet_id: String, seed_i: int = 2) -> void:
	_planet = planet
	_radius = radius
	_atm = atmosphere_height
	_planet_id = planet_id
	_seed = seed_i
	_biomes = _Cat.planet_biomes(planet_id)


func set_observer(n: Node3D) -> void:
	_observer = n
	_last_cell = Vector2i(999999, 999999)


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_accum += delta
	_animate(delta)
	if _accum < STREAM_HZ:
		return
	_accum = 0.0
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	var dist: float = _observer.global_position.distance_to(_planet.global_position)
	var alt: float = dist - _radius
	if alt < -12.0 or alt > maxf(_atm * 1.4, 400.0):
		_set_vis(false)
		return
	_set_vis(true)
	if not _built:
		_spawn_pool()
		_built = true
	var cell: Vector2i = _Math.cell_of(_planet.global_position, _radius, _observer.global_position, CELL_M)
	if cell != _last_cell:
		_last_cell = cell
		_place_cell(cell, alt)


func _set_vis(v: bool) -> void:
	for a in _actors:
		var n: Node3D = a.get("node") as Node3D
		if n != null and is_instance_valid(n):
			n.visible = v


func _count() -> int:
	var n: int = COUNT_BASE
	var gq = get_node_or_null("/root/GraphicsQuality")
	if gq != null:
		match int(gq.tier):
			0:
				n = 6
			2, 3:
				n = 14
	return n


func _spawn_pool() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 9001
	var nmax: int = _count()
	for i in nmax:
		var biome: String = "temperate_forest"
		if _biomes.size() > 0:
			biome = str(_biomes[i % _biomes.size()])
		var spec: Dictionary = _Cat.pick_species(biome, rng)
		if spec.is_empty():
			continue
		var node: Node3D = _make_actor(spec, rng)
		if node == null:
			continue
		add_child(node)
		_actors.append({
			"node": node,
			"domain": int(spec.get("domain", 1)),
			"speed": float(spec.get("speed", 1.0)),
			"phase": rng.randf() * TAU,
			"base": Vector3.ZERO,
			"id": str(spec.get("id", "")),
		})
	print("[SurfaceFauna] pool=", _actors.size(), " planet=", _planet_id)


func _make_actor(spec: Dictionary, rng: RandomNumberGenerator) -> Node3D:
	var mesh_rel: String = str(spec.get("mesh", ""))
	if mesh_rel != "":
		var path: String = ""
		if _AP != null and _AP.has_method("resolve"):
			path = str(_AP.resolve(mesh_rel))
		if path != "" and FileAccess.file_exists(path):
			var prop := Node3D.new()
			var ps: Script = load("res://scripts/assets/GlbProp.gd")
			prop.set_script(ps)
			prop.set("relative_path", mesh_rel)
			prop.set("scale_factor", float(spec.get("scale", 1.0)) * rng.randf_range(0.85, 1.15))
			prop.set("add_static_collision", false)
			return prop
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var shape: String = str(spec.get("shape", "sphere"))
	var sc: float = float(spec.get("scale", 0.6))
	match shape:
		"capsule":
			var c := CapsuleMesh.new()
			c.radius = 0.18 * sc
			c.height = 0.55 * sc
			mi.mesh = c
		"quad":
			var b := BoxMesh.new()
			b.size = Vector3(0.55 * sc, 0.12 * sc, 0.35 * sc)
			mi.mesh = b
		_:
			var s := SphereMesh.new()
			s.radius = 0.22 * sc
			s.height = 0.44 * sc
			mi.mesh = s
	var mat := StandardMaterial3D.new()
	var col := Color(0.5, 0.8, 1.0)
	if spec.has("color"):
		col = spec["color"] as Color
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.85
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return root


func _place_cell(cell: Vector2i, alt: float) -> void:
	if _planet == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(cell) + str(_seed))
	var dir: Vector3 = _Math.cell_center_dir(cell, _radius, CELL_M)
	var center: Vector3 = _planet.global_position + dir * _radius
	var up: Vector3 = dir
	var tang: Array = _Math.stable_tangent(up)
	var east: Vector3 = tang[0] as Vector3
	var north: Vector3 = tang[1] as Vector3
	for i in _actors.size():
		var a: Dictionary = _actors[i]
		var node: Node3D = a["node"] as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var domain: int = int(a["domain"])
		var ox: float = rng.randf_range(-CELL_M * 0.4, CELL_M * 0.4)
		var oz: float = rng.randf_range(-CELL_M * 0.4, CELL_M * 0.4)
		var h: float = 0.4
		match domain:
			_Cat.Domain.AQUATIC:
				h = rng.randf_range(-1.2, 0.5)
			_Cat.Domain.TERRESTRIAL:
				h = rng.randf_range(0.2, 1.5)
			_Cat.Domain.AERIAL:
				h = rng.randf_range(8.0, 55.0)
			_Cat.Domain.SPACE:
				h = rng.randf_range(maxf(_atm * 0.55, 80.0), maxf(_atm * 1.1, 160.0))
		if domain == _Cat.Domain.SPACE and alt < _atm * 0.4:
			h = rng.randf_range(40.0, 90.0)
		if domain == _Cat.Domain.AQUATIC and alt > 40.0:
			h = rng.randf_range(0.0, 2.0)
		var pos: Vector3 = center + east * ox + north * oz + up * h
		node.global_position = pos
		var look: Vector3 = pos + east * cos(float(a["phase"])) + north * sin(float(a["phase"]))
		if look.distance_to(pos) > 0.01:
			node.look_at(look, up)
		a["base"] = pos
		a["up"] = up
		a["east"] = east
		a["north"] = north
		_actors[i] = a


func _animate(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	for i in _actors.size():
		var a: Dictionary = _actors[i]
		var node: Node3D = a.get("node") as Node3D
		if node == null or not is_instance_valid(node) or not node.visible:
			continue
		if not a.has("base") or not a.has("up"):
			continue
		var base: Vector3 = a["base"] as Vector3
		var up: Vector3 = a["up"] as Vector3
		var east: Vector3 = a.get("east", Vector3.RIGHT) as Vector3
		var north: Vector3 = a.get("north", Vector3.FORWARD) as Vector3
		var ph: float = float(a["phase"])
		var sp: float = float(a["speed"])
		var domain: int = int(a["domain"])
		var wobble: Vector3 = east * cos(t * sp + ph) * 1.8 + north * sin(t * sp * 0.7 + ph) * 1.8
		var bob_amp: float = 0.15
		if domain == _Cat.Domain.AERIAL:
			bob_amp = 0.8
		var bob: Vector3 = up * sin(t * (1.2 + sp * 0.3) + ph) * bob_amp
		if domain == _Cat.Domain.SPACE:
			wobble *= 2.2
			bob = up * sin(t * 0.5 + ph) * 1.5
		node.global_position = base + wobble + bob
